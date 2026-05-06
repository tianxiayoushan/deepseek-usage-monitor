// src/components/MiniTrendCard.tsx
// Industrial sparkline — square joints, monochrome
import type { TrendPoint } from '../mockData';
import type { Language } from '../i18n';

interface Props {
  title: string;
  data: TrendPoint[];
  formatValue?: (v: number) => string;
  lang?: Language;
}

function defaultFmt(v: number): string {
  if (v >= 1_000_000) return `${(v/1_000_000).toFixed(1)}M`;
  if (v >= 1_000)     return `${(v/1_000).toFixed(0)}K`;
  return v.toFixed(v < 10 ? 2 : 0);
}

export default function MiniTrendCard({ title, data, formatValue = defaultFmt, lang }: Props) {
  if (!data || data.length < 2) return null;

  const vals    = data.map(d => d.value);
  const min     = Math.min(...vals);
  const max     = Math.max(...vals);
  const range   = max - min || 1;
  const current = vals[vals.length - 1];

  const W = 190, H = 52, PX = 4, PY = 7;

  const toX = (i: number) => PX + (i / (vals.length - 1)) * (W - PX * 2);
  const toY = (v: number) => H - PY - ((v - min) / range) * (H - PY * 2);

  const pts = vals.map((v,i) => `${toX(i).toFixed(1)},${toY(v).toFixed(1)}`).join(' ');
  const lastX = toX(vals.length - 1);
  const lastY = toY(current);

  return (
    <div className="card" style={{ flex:1, padding:'10px 12px 8px' }}>
      {/* Label + current value */}
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom:6 }}>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:9 }}>{title}</span>
        <span className="font-num" style={{ fontSize:13, color:'var(--text-strong)', fontWeight:700 }}>
          {formatValue(current)}
        </span>
      </div>

      {/* SVG sparkline */}
      <div style={{ overflow:'hidden', height:H }}>
        <svg viewBox={`0 0 ${W} ${H}`} width="100%" height={H} preserveAspectRatio="none">
          <polyline
            className="trend-line"
            points={pts}
            style={{ fill:'none', stroke:'var(--trend-line)', strokeWidth:1.5 }}
            strokeLinejoin="miter" strokeLinecap="square"
          />
          {/* Square endpoint marker */}
          <rect x={parseFloat(lastX.toFixed(1)) - 2.5} y={parseFloat(lastY.toFixed(1)) - 2.5}
            width={5} height={5}
            style={{ fill:'var(--trend-line)' }}
          />
        </svg>
      </div>

      {/* X range labels */}
      <div style={{ display:'flex', justifyContent:'space-between', marginTop:3 }}>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:8, color:'var(--text-muted)' }}>
          {data[0].label}
        </span>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:8, color:'var(--text-muted)' }}>
          {data[data.length-1].label}
        </span>
      </div>
    </div>
  );
}
