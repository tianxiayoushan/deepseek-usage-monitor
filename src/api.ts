// src/api.ts
// API abstraction layer for DeepSeek Usage Monitor
// v0.2 – real DeepSeek balance; v0.2.1 – historical spend + settings

import type { DashboardData, RequestRecord } from './mockData';
import { mockDashboardData } from './mockData';

// ── Response types ────────────────────────────────────────────────────────────

export interface BalanceResponse {
  available: boolean;
  currency: string;
  total_balance: number | null;
  granted_balance?: number;
  topped_up_balance?: number;
  initial_total_credit?: number | null;
  historical_total_spend?: number | null;
  historical_total_spend_available?: boolean;
  error?: string;
  updated_at: string;
}

export interface SettingsResponse {
  api_key_configured: boolean;
  initial_total_credit: number | null;
  initial_total_credit_configured: boolean;
  updated_at: string;
}

export interface SaveSettingsPayload {
  initial_total_credit?: number | null;
  deepseek_api_key?: string;
}

// ── Constants ─────────────────────────────────────────────────────────────────

const BACKEND_URL = 'http://localhost:8789';

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Simulate realistic network latency (for mock fallback paths) */
const delay = (ms: number) => new Promise<void>((res) => setTimeout(res, ms));
const jitter = () => Math.random() * 150 + 50; // 50–200ms

// ── API object ────────────────────────────────────────────────────────────────

export const api = {
  /**
   * Fetch full dashboard snapshot.
   * – Tries real balance from backend; falls back gracefully to mock.
   * – If historical_total_spend is available, overrides mock totalSpend.
   */
  getDashboardData: async (): Promise<DashboardData> => {
    await delay(jitter());

    let realBalance = mockDashboardData.balance;
    let maxBalance = mockDashboardData.maxBalance;
    let totalSpend = mockDashboardData.totalSpend;

    try {
      const response = await fetch(`${BACKEND_URL}/api/balance`);
      if (response.ok) {
        const data: BalanceResponse = await response.json();

        // ── Balance ──────────────────────────────────────────────────────────
        if (data.available && typeof data.total_balance === 'number') {
          realBalance = data.total_balance;

          if (realBalance <= 100) {
            maxBalance = 100;
          } else {
            maxBalance = Math.ceil((realBalance * 1.2) / 10) * 10;
          }
        } else if (data.error) {
          console.warn('[DeepSeek Balance]', data.error);
        }

        // ── Historical spend ─────────────────────────────────────────────────
        if (
          data.historical_total_spend_available === true &&
          typeof data.historical_total_spend === 'number'
        ) {
          totalSpend = data.historical_total_spend;
        } else {
          console.warn(
            '[DeepSeek Balance] historical spend baseline is not configured – using mock totalSpend.'
          );
        }
      } else {
        console.warn(`[DeepSeek API] Backend returned status ${response.status}`);
      }
    } catch (e) {
      console.warn('[DeepSeek API] Failed to connect to backend, using mock data.', e);
    }

    return {
      ...mockDashboardData,
      balance: realBalance,
      maxBalance,
      todayRequests: mockDashboardData.todayRequests,
      todayTokens: mockDashboardData.todayTokens,
      todaySpend: mockDashboardData.todaySpend,
      totalSpend,
      lastUpdatedAt: new Date().toISOString(),
    };
  },

  /**
   * Fetch current balance only (lightweight, high-frequency).
   */
  getBalance: async (): Promise<number> => {
    try {
      const response = await fetch(`${BACKEND_URL}/api/balance`);
      if (response.ok) {
        const data: BalanceResponse = await response.json();
        if (data.available && typeof data.total_balance === 'number') {
          return data.total_balance;
        }
      }
    } catch {
      // Fallback silently
    }
    await delay(40);
    return mockDashboardData.balance;
  },

  /**
   * Fetch most recent N request records (mock).
   */
  getRecentRequests: async (limit = 10): Promise<RequestRecord[]> => {
    await delay(jitter());
    return mockDashboardData.recentRequests.slice(0, limit);
  },

  // ── Settings endpoints ──────────────────────────────────────────────────────

  /**
   * Fetch backend settings (API key status + initial total credit).
   */
  getSettings: async (): Promise<SettingsResponse | null> => {
    try {
      const response = await fetch(`${BACKEND_URL}/api/settings`);
      if (response.ok) return (await response.json()) as SettingsResponse;
    } catch {
      // Backend not running
    }
    return null;
  },

  /**
   * Save settings to backend (persisted in local_settings.json).
   */
  saveSettings: async (payload: SaveSettingsPayload): Promise<boolean> => {
    try {
      const response = await fetch(`${BACKEND_URL}/api/settings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      return response.ok;
    } catch {
      return false;
    }
  },
};
