// src/mockData.ts
// All mock data for DeepSeek Usage Monitor v0.1
// Replace with real API responses in future versions

export interface ModelUsageData {
  name: string;
  requests: number;
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  estimatedCost: number; // CNY
  percentage: number;    // 0-100
}

export interface RequestRecord {
  id: string;
  timestamp: string;       // ISO 8601
  model: string;
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  estimatedCost: number;   // CNY
  status: 'success' | 'error';
  latencyMs: number;
}

export interface TrendPoint {
  label: string;   // e.g. "14:00"
  value: number;
}

export interface DashboardData {
  balance: number;          // Current balance in CNY
  maxBalance: number;       // For gauge scale (e.g. 150)
  todayRequests: number;
  todayTokens: number;      // Raw number (display as "1.28M")
  todaySpend: number;       // CNY
  totalSpend: number;       // CNY
  models: ModelUsageData[];
  recentRequests: RequestRecord[];
  spendTrend: TrendPoint[];
  tokensTrend: TrendPoint[];
  requestsTrend: TrendPoint[];
  lastUpdatedAt: string;    // ISO 8601
}

// ─── Recent Requests Mock ────────────────────────────────────────────────────

const now = new Date();
const minutesAgo = (n: number) => new Date(now.getTime() - n * 60_000).toISOString();

export const mockRecentRequests: RequestRecord[] = [
  {
    id: 'req-001',
    timestamp: minutesAgo(1),
    model: 'deepseek-v4-flash',
    promptTokens: 8420,
    completionTokens: 1240,
    totalTokens: 9660,
    estimatedCost: 0.0077,
    status: 'success',
    latencyMs: 843,
  },
  {
    id: 'req-002',
    timestamp: minutesAgo(3),
    model: 'deepseek-v4-pro',
    promptTokens: 12300,
    completionTokens: 2800,
    totalTokens: 15100,
    estimatedCost: 0.0453,
    status: 'success',
    latencyMs: 2341,
  },
  {
    id: 'req-003',
    timestamp: minutesAgo(5),
    model: 'deepseek-v4-flash',
    promptTokens: 4200,
    completionTokens: 890,
    totalTokens: 5090,
    estimatedCost: 0.0041,
    status: 'success',
    latencyMs: 512,
  },
  {
    id: 'req-004',
    timestamp: minutesAgo(8),
    model: 'deepseek-v4-flash',
    promptTokens: 6800,
    completionTokens: 0,
    totalTokens: 6800,
    estimatedCost: 0.0034,
    status: 'error',
    latencyMs: 12000,
  },
  {
    id: 'req-005',
    timestamp: minutesAgo(12),
    model: 'deepseek-v4-pro',
    promptTokens: 9100,
    completionTokens: 3200,
    totalTokens: 12300,
    estimatedCost: 0.0369,
    status: 'success',
    latencyMs: 1987,
  },
  {
    id: 'req-006',
    timestamp: minutesAgo(18),
    model: 'deepseek-v4-flash',
    promptTokens: 15600,
    completionTokens: 2100,
    totalTokens: 17700,
    estimatedCost: 0.0142,
    status: 'success',
    latencyMs: 1123,
  },
  {
    id: 'req-007',
    timestamp: minutesAgo(24),
    model: 'deepseek-v4-flash',
    promptTokens: 3400,
    completionTokens: 780,
    totalTokens: 4180,
    estimatedCost: 0.0033,
    status: 'success',
    latencyMs: 398,
  },
  {
    id: 'req-008',
    timestamp: minutesAgo(31),
    model: 'deepseek-v4-pro',
    promptTokens: 18200,
    completionTokens: 4100,
    totalTokens: 22300,
    estimatedCost: 0.0669,
    status: 'success',
    latencyMs: 3102,
  },
  {
    id: 'req-009',
    timestamp: minutesAgo(40),
    model: 'deepseek-v4-flash',
    promptTokens: 7700,
    completionTokens: 1560,
    totalTokens: 9260,
    estimatedCost: 0.0074,
    status: 'success',
    latencyMs: 701,
  },
  {
    id: 'req-010',
    timestamp: minutesAgo(55),
    model: 'deepseek-v4-flash',
    promptTokens: 5100,
    completionTokens: 0,
    totalTokens: 5100,
    estimatedCost: 0.0026,
    status: 'error',
    latencyMs: 30000,
  },
];

// ─── Trend Data Mock ─────────────────────────────────────────────────────────

const generateTrend = (
  baseValue: number,
  variance: number,
  count = 12
): TrendPoint[] => {
  const labels = [
    '04:00','05:00','06:00','07:00','08:00','09:00',
    '10:00','11:00','12:00','13:00','14:00','15:00',
  ];
  let running = baseValue * 0.2;
  return labels.slice(0, count).map((label, i) => {
    running += Math.random() * variance * (i < 8 ? 0.4 : 1.2);
    return { label, value: parseFloat(running.toFixed(4)) };
  });
};

export const mockSpendTrend = generateTrend(1.27, 0.15);
export const mockTokensTrend = generateTrend(1_280_000, 120_000);
export const mockRequestsTrend = generateTrend(142, 14);

// ─── Main Dashboard Data ──────────────────────────────────────────────────────

export const mockDashboardData: DashboardData = {
  balance: 83.42,
  maxBalance: 100,
  todayRequests: 142,
  todayTokens: 1_280_000,
  todaySpend: 1.27,
  totalSpend: 16.58,
  models: [
    {
      name: 'deepseek-v4-flash',
      requests: 130,
      promptTokens: 980_000,
      completionTokens: 210_000,
      totalTokens: 1_190_000,
      estimatedCost: 0.91,
      percentage: 90.1,
    },
    {
      name: 'deepseek-v4-pro',
      requests: 12,
      promptTokens: 72_000,
      completionTokens: 22_000,
      totalTokens: 94_000,
      estimatedCost: 0.36,
      percentage: 9.9,
    },
  ],
  recentRequests: mockRecentRequests,
  spendTrend: mockSpendTrend,
  tokensTrend: mockTokensTrend,
  requestsTrend: mockRequestsTrend,
  lastUpdatedAt: new Date().toISOString(),
};
