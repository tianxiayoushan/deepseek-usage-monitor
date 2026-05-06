// src/App.tsx
import { useState, useEffect, useCallback } from 'react';
import { Sun, Moon, PanelRightOpen, PanelRightClose, Settings, SlidersHorizontal } from 'lucide-react';
import { api } from './api';
import type { DashboardData } from './mockData';
import { mockDashboardData } from './mockData';
import CircularGauge from './components/CircularGauge';
import MetricCard from './components/MetricCard';
import ModelUsage from './components/ModelUsage';
import RecentRequests from './components/RecentRequests';
import MiniTrendCard from './components/MiniTrendCard';
import RefreshControl from './components/RefreshControl';
import SettingsPanel from './components/SettingsPanel';
import { t } from './i18n';
import type { Language } from './i18n';

type RefreshInterval = 5 | 10 | 30;
type Theme = 'dark' | 'light';

const STAGE_W = 1600;
const STAGE_H = 900;

function fmtTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(2)}M`;
  if (n >= 1_000)     return `${(n / 1_000).toFixed(0)}K`;
  return String(n);
}

export default function App() {
  // ── Theme ──────────────────────────────────────────────────────────────────
  const [theme, setTheme] = useState<Theme>(() =>
    (localStorage.getItem('ds-theme') as Theme) ?? 'dark'
  );
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('ds-theme', theme);
  }, [theme]);

  // ── Focus Mode ─────────────────────────────────────────────────────────────
  const [isFocusMode, setIsFocusMode] = useState<boolean>(() =>
    localStorage.getItem('ds-focus-mode') === 'true'
  );
  useEffect(() => {
    localStorage.setItem('ds-focus-mode', String(isFocusMode));
  }, [isFocusMode]);
  
  // ── Language ───────────────────────────────────────────────────────────────
  const [lang, setLang] = useState<Language>(() =>
    (localStorage.getItem('ds-language') as Language) ?? 'zh'
  );
  useEffect(() => {
    localStorage.setItem('ds-language', lang);
  }, [lang]);
  
  // ── Gauge Max Amount ───────────────────────────────────────────────────────
  const [gaugeMaxAmount, setGaugeMaxAmount] = useState<number>(() => {
    const saved = localStorage.getItem('ds-gauge-max-amount');
    const val = saved ? parseInt(saved, 10) : 100;
    if (isNaN(val) || val < 100 || val > 1000 || val % 100 !== 0) return 100;
    return val;
  });
  useEffect(() => {
    localStorage.setItem('ds-gauge-max-amount', String(gaugeMaxAmount));
  }, [gaugeMaxAmount]);

  const [showGaugePopover, setShowGaugePopover] = useState(false);

  // ── Settings panel ─────────────────────────────────────────────────────────
  const [showSettings, setShowSettings] = useState(false);

  // ── Stage scale ────────────────────────────────────────────────────────────
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const calc = () =>
      setScale(Math.min(window.innerWidth / STAGE_W, window.innerHeight / STAGE_H));
    calc();
    window.addEventListener('resize', calc);
    return () => window.removeEventListener('resize', calc);
  }, []);

  // ── Data & refresh ─────────────────────────────────────────────────────────
  const [data, setData] = useState<DashboardData>(mockDashboardData);
  const [interval, setInterval_] = useState<RefreshInterval>(5);
  const [isLoading, setIsLoading] = useState(false);
  const [uptime, setUptime] = useState(0);

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    try { setData(await api.getDashboardData()); }
    catch (e) { console.error('[Monitor]', e); }
    finally   { setIsLoading(false); }
  }, []);

  useEffect(() => {
    fetchData();
    const t = window.setInterval(fetchData, interval * 1000);
    return () => window.clearInterval(t);
  }, [interval, fetchData]);

  useEffect(() => {
    const t = window.setInterval(() => setUptime(s => s + 1), 1000);
    return () => window.clearInterval(t);
  }, []);

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    /* Viewport: centers and clips the fixed stage */
    <div style={{
      width: '100vw', height: '100vh',
      overflow: 'hidden',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'var(--bg)',
    }}>
      {/* Stage: fixed 1600×900, scaled proportionally */}
      <div style={{
        width: STAGE_W, height: STAGE_H,
        flexShrink: 0,
        transform: `scale(${scale})`,
        transformOrigin: 'center center',
        display: 'flex',
        overflow: 'hidden',
        background: 'var(--bg)',
      }}>

        {/* ══════ LEFT PANEL (Gauge Focus Area) ══════ */}
        <div style={{
          width: isFocusMode ? STAGE_W : 768,
          flexShrink: 0, height: STAGE_H,
          background: 'var(--bg-left)',
          borderRight: isFocusMode ? 'none' : '1px solid var(--border-subtle)',
          display: 'flex', flexDirection: 'column',
          padding: isFocusMode ? '40px 60px' : '24px 20px 20px 28px',
          transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          position: 'relative',
        }}>
          {/* Logo */}
          <div style={{ marginBottom: 18, userSelect: 'none' }}>
            <div className={`font-num ${lang === 'zh' ? 'label-caps zh' : ''}`} style={{
              fontSize: isFocusMode ? 16 : 13, letterSpacing: lang === 'zh' ? '0.12em' : '0.32em',
              color: 'var(--text)', fontWeight: 700,
              textTransform: 'uppercase', transition: 'font-size 0.4s',
            }}>DeepSeek</div>
            <div className={`font-num ${lang === 'zh' ? 'label-caps zh' : ''}`} style={{
              fontSize: isFocusMode ? 10 : 9, letterSpacing: lang === 'zh' ? '0.15em' : '0.4em',
              color: 'var(--text-muted)', marginTop: 2,
              textTransform: 'uppercase', transition: 'font-size 0.4s',
            }}>{t(lang, 'usageMonitor')}</div>
            <div style={{
              height: 1, width: 40, marginTop: 10,
              background: 'var(--border)',
            }} />
          </div>

          {/* Gauge — Centered and scaled in Focus Mode */}
          <div style={{
            flex: 1, display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            transform: isFocusMode ? 'scale(1.16) translateY(-20px)' : 'scale(1)',
            transition: 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          }}>
            <CircularGauge
              balance={data.balance}
              maxBalance={data.balance > gaugeMaxAmount ? Math.ceil(data.balance * 1.2 / 10) * 10 : gaugeMaxAmount}
              todaySpend={data.todaySpend}
              totalSpend={data.totalSpend}
              uptime={uptime}
              isFocused={isFocusMode}
              lang={lang}
              t={t}
            />
          </div>

          {/* Mini Trend Cards — Hidden in Focus Mode */}
          {!isFocusMode && (
            <div style={{
              display: 'flex', gap: 8,
              marginTop: 14, justifyContent: 'flex-start',
              transition: 'all 0.4s',
            }}>
              <MiniTrendCard title={t(lang, 'cost')}    data={data.spendTrend}    formatValue={v => `¥${v.toFixed(2)}`} lang={lang} />
              <MiniTrendCard title={t(lang, 'todayTokens')}   data={data.tokensTrend}   formatValue={v => fmtTokens(v)} lang={lang} />
              <MiniTrendCard title={t(lang, 'todayRequests')} data={data.requestsTrend} formatValue={v => String(Math.round(v))} lang={lang} />
            </div>
          )}
        </div>

        {/* ══════ RIGHT PANEL (Data Area) ══════ */}
        <div style={{
          flex: 1, height: STAGE_H,
          background: 'var(--bg-right)',
          display: isFocusMode ? 'none' : 'flex',
          flexDirection: 'column',
          padding: '24px 32px 20px 28px',
          gap: 16, overflow: 'hidden',
          opacity: isFocusMode ? 0 : 1,
          transition: 'opacity 0.3s',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
            <RefreshControl
              interval={interval}
              onChange={setInterval_}
              isLoading={isLoading}
              lastUpdatedAt={data.lastUpdatedAt}
              lang={lang}
              t={t}
            />
            
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative' }}>
              {/* Gauge Range Trigger */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginRight: 4 }}>
                <span className="font-num label-caps" style={{ fontSize: 9, color: 'var(--text-muted)' }}>MAX {gaugeMaxAmount}</span>
                <button
                  className="theme-toggle"
                  onClick={() => setShowGaugePopover(!showGaugePopover)}
                  title={t(lang, 'adjustGaugeMax')}
                  aria-label={t(lang, 'adjustGaugeMax')}
                  style={{ background: showGaugePopover ? 'var(--bg-card-hover)' : 'transparent' }}
                >
                  <SlidersHorizontal size={14} />
                </button>
              </div>

              {/* Gauge Range Popover */}
              {showGaugePopover && (
                <div className="popover" style={{ position: 'absolute', top: 40, right: 0, width: 200 }}>
                  <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 10, marginBottom: 12 }}>
                    {t(lang, 'gaugeRange')}
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                    <span className="font-num" style={{ fontSize: 12, fontWeight: 700 }}>MAX {gaugeMaxAmount}</span>
                    <span className="font-num" style={{ fontSize: 10, color: 'var(--text-muted)' }}>CNY</span>
                  </div>
                  <input
                    type="range"
                    min="100"
                    max="1000"
                    step="100"
                    value={gaugeMaxAmount}
                    onChange={(e) => setGaugeMaxAmount(parseInt(e.target.value, 10))}
                    className="industrial-slider"
                  />
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
                    <span className="font-num" style={{ fontSize: 8, color: 'var(--text-muted)' }}>100</span>
                    <span className="font-num" style={{ fontSize: 8, color: 'var(--text-muted)' }}>1000</span>
                  </div>
                </div>
              )}

              <button
                className="theme-toggle"
                onClick={() => setLang(l => l === 'en' ? 'zh' : 'en')}
                title={lang === 'zh' ? 'Switch to English' : '切换到中文'}
                aria-label={t(lang, 'changeLanguage')}
                style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.08em', fontFamily: 'ui-monospace,monospace' }}
              >
                {lang === 'en' ? 'EN' : 'CN'}
              </button>

              <button
                className="theme-toggle"
                onClick={() => setIsFocusMode(true)}
                title={t(lang, 'hidePanel')}
                aria-label={t(lang, 'hidePanel')}
              >
                <PanelRightClose size={15} />
              </button>

              <button
                id="open-settings-btn"
                className="theme-toggle"
                onClick={() => setShowSettings(true)}
                title={t(lang, 'openSettings')}
                aria-label={t(lang, 'openSettings')}
              >
                <Settings size={15} />
              </button>

              <button
                className="theme-toggle"
                onClick={() => setTheme(t => t === 'dark' ? 'light' : 'dark')}
                title={t(lang, 'toggleTheme')}
                aria-label={t(lang, 'toggleTheme')}
              >
                {theme === 'dark' ? <Sun size={15} /> : <Moon size={15} />}
              </button>
            </div>
          </div>

          {/* 2×2 Metric Cards */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <MetricCard label={t(lang, 'todayRequests')} value={String(data.todayRequests)} accent="white" lang={lang} />
            <MetricCard label={t(lang, 'todayTokens')}   value={fmtTokens(data.todayTokens)}  accent="blue"  lang={lang} />
            <MetricCard label={t(lang, 'todaySpend')}    value={`¥${data.todaySpend.toFixed(2)}`} accent="red" sub="CNY" lang={lang} />
            <MetricCard label={t(lang, 'totalSpend')}    value={`¥${data.totalSpend.toFixed(2)}`} accent="white" sub={t(lang, 'cumulative')} lang={lang} />
          </div>

          {/* Model Usage */}
          <ModelUsage models={data.models} lang={lang} t={t} />

          {/* Recent Requests */}
          <RecentRequests requests={data.recentRequests} lang={lang} t={t} />

          {/* Footer */}
          {!isFocusMode && (
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              marginTop: 'auto', paddingTop: 8,
              borderTop: '1px solid var(--border-subtle)',
            }}>
              <span className={`label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 9 }}>
                DeepSeek Usage Monitor v0.2.3
              </span>
              <span className={`label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 9 }}>
                {t(lang, 'refresh_s')}
              </span>
            </div>
          )}
        </div>

        {/* Floating Controls (Visible only in Focus Mode) */}
        {isFocusMode && (
          <div style={{
            position: 'absolute', top: 24, right: 32,
            display: 'flex', gap: 12, alignItems: 'center',
          }}>
            {/* Gauge Range in Focus Mode */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative' }}>
               <span className="font-num label-caps" style={{ fontSize: 9, color: 'var(--text-muted)' }}>MAX {gaugeMaxAmount}</span>
               <button
                  className="theme-toggle"
                  onClick={() => setShowGaugePopover(!showGaugePopover)}
                  title={t(lang, 'adjustGaugeMax')}
                  aria-label={t(lang, 'adjustGaugeMax')}
                  style={{ background: 'var(--panel-raised)', border: showGaugePopover ? '1px solid var(--border-strong)' : '1px solid var(--border)' }}
                >
                  <SlidersHorizontal size={14} />
                </button>
                {showGaugePopover && (
                  <div className="popover" style={{ position: 'absolute', top: 40, right: 0, width: 200 }}>
                    <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 10, marginBottom: 12 }}>
                      {t(lang, 'gaugeRange')}
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                      <span className="font-num" style={{ fontSize: 12, fontWeight: 700 }}>MAX {gaugeMaxAmount}</span>
                    </div>
                    <input
                      type="range"
                      min="100"
                      max="1000"
                      step="100"
                      value={gaugeMaxAmount}
                      onChange={(e) => setGaugeMaxAmount(parseInt(e.target.value, 10))}
                      className="industrial-slider"
                    />
                  </div>
                )}
            </div>

            <button
              className="theme-toggle"
              onClick={() => setLang(l => l === 'en' ? 'zh' : 'en')}
              title={lang === 'zh' ? 'Switch to English' : '切换到中文'}
              aria-label={t(lang, 'changeLanguage')}
              style={{ background: 'var(--panel-raised)', fontSize: 9, fontWeight: 700, letterSpacing: '0.08em', fontFamily: 'ui-monospace,monospace' }}
            >
              {lang === 'en' ? 'EN' : 'CN'}
            </button>

            <button
              className="theme-toggle"
              onClick={() => setIsFocusMode(false)}
              title={t(lang, 'showPanel')}
              aria-label={t(lang, 'showPanel')}
              style={{ background: 'var(--panel-raised)' }}
            >
              <PanelRightOpen size={15} />
            </button>

            <button
              id="open-settings-btn-focus"
              className="theme-toggle"
              onClick={() => setShowSettings(true)}
              title={t(lang, 'openSettings')}
              aria-label={t(lang, 'openSettings')}
              style={{ background: 'var(--panel-raised)' }}
            >
              <Settings size={15} />
            </button>

            <button
              className="theme-toggle"
              onClick={() => setTheme(t => t === 'dark' ? 'light' : 'dark')}
              title={t(lang, 'toggleTheme')}
              aria-label={t(lang, 'toggleTheme')}
              style={{ background: 'var(--panel-raised)' }}
            >
              {theme === 'dark' ? <Sun size={15} /> : <Moon size={15} />}
            </button>
          </div>
        )}

        {/* Settings overlay */}
        {showSettings && (
          <SettingsPanel
            onClose={() => setShowSettings(false)}
            onSaved={() => { setShowSettings(false); fetchData(); }}
            lang={lang}
            t={t}
          />
        )}

      </div>
    </div>
  );
}
