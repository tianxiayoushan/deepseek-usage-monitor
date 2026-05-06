// src/components/RefreshControl.tsx
// Mechanical segmented switch — industrial toggle
import { RefreshCw } from 'lucide-react';

interface Props {
  interval: 5 | 10 | 30;
  onChange: (v: 5 | 10 | 30) => void;
  isLoading: boolean;
  lastUpdatedAt: string;
  lang: any;
  t: any;
}

const OPTS: Array<5|10|30> = [5, 10, 30];

export default function RefreshControl({ interval, onChange, isLoading, lastUpdatedAt, lang, t }: Props) {
  const timeStr = lastUpdatedAt
    ? new Date(lastUpdatedAt).toLocaleTimeString(lang === 'zh' ? 'zh-CN' : 'en-US', {
        hour:'2-digit', minute:'2-digit', second:'2-digit', hour12:false,
      })
    : '--:--:--';

  return (
    <div style={{ display:'flex', alignItems:'center', gap:16 }}>
      {/* Status dot + label */}
      <div style={{ display:'flex', alignItems:'center', gap:7 }}>
        <span className="dot-live" />
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:10, color:'var(--text-secondary)' }}>
          {t(lang, 'autoRefresh')}
        </span>
      </div>

      {/* Divider */}
      <div style={{ width:1, height:14, background:'var(--border)' }} />

      {/* Last updated time */}
      <span className="font-num" style={{ fontSize:11, color:'var(--text-muted)', letterSpacing:'0.1em' }}>
        {timeStr}
      </span>

      {/* Loading spinner */}
      {isLoading && (
        <RefreshCw size={11} className="spin" style={{ color:'var(--text-muted)' }} />
      )}

      {/* Interval buttons — mechanical segmented switch */}
      <div style={{
        display:'flex', gap:2, borderRadius:4, overflow:'hidden',
        padding:2,
        border:'1px solid var(--border)',
        background:'var(--bg-inset)',
      }}>
        {OPTS.map(v => (
          <button key={v} onClick={() => onChange(v)} style={{
            padding:'4px 14px',
            fontFamily:'ui-monospace,monospace',
            fontSize:11, letterSpacing:'0.1em', cursor:'pointer',
            border: interval === v ? '1px solid var(--border-strong)' : '1px solid transparent',
            borderRadius: 3,
            outline:'none',
            transition:'all 0.12s',
            background: interval === v ? 'var(--text-strong)' : 'transparent',
            color:       interval === v ? 'var(--bg)' : 'var(--text-muted)',
            fontWeight:  interval === v ? 700 : 400,
          }}>
            {v}s
          </button>
        ))}
      </div>
    </div>
  );
}
