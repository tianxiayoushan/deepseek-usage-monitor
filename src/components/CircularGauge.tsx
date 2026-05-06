import type { Language, TranslationFunction } from '../i18n';

interface Props {
  balance: number;
  maxBalance: number;
  todaySpend: number;
  totalSpend: number;
  uptime: number;
  isFocused?: boolean;
  lang: Language;
  t: TranslationFunction;
}

function pad2(n: number) { return String(n).padStart(2, '0'); }
function fmtUptime(s: number) {
  return `${pad2(Math.floor(s / 3600))}:${pad2(Math.floor((s % 3600) / 60))}:${pad2(s % 60)}`;
}
function fmtTime(d: Date, lang: Language) {
  return d.toLocaleTimeString(lang === 'zh' ? 'zh-CN' : 'en-US', { hour: '2-digit', minute: '2-digit', hour12: true }).toUpperCase();
}
function fmtDate(d: Date, lang: Language) {
  return d.toLocaleDateString(lang === 'zh' ? 'zh-CN' : 'en-US', { weekday: 'long', month: 'long', day: 'numeric' }).toUpperCase();
}

const MATRIX: Record<string, string[]> = {
  "0": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
  "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
  "2": ["11111", "00001", "00001", "11111", "10000", "10000", "11111"],
  "3": ["11111", "00001", "00001", "01111", "00001", "00001", "11111"],
  "4": ["10001", "10001", "10001", "11111", "00001", "00001", "00001"],
  "5": ["11111", "10000", "10000", "11111", "00001", "00001", "11111"],
  "6": ["11111", "10000", "10000", "11111", "10001", "10001", "11111"],
  "7": ["11111", "00001", "00001", "00001", "00001", "00001", "00001"],
  "8": ["11111", "10001", "10001", "11111", "10001", "10001", "11111"],
  "9": ["11111", "10001", "10001", "11111", "00001", "00001", "11111"],
  ".": ["0", "0", "0", "0", "0", "1", "1"],
  "¥": ["10001", "01010", "00100", "11111", "00100", "11111", "00100"]
};

function DotMatrixNumber({ text, x, y, dotSize = 8, dotGap = 2, charGap = 12 }: { text: string, x: number, y: number, dotSize?: number, dotGap?: number, charGap?: number }) {
  const chars = text.split("");
  
  const { items: charsToRender, currentX: totalWidth } = chars.reduce((acc, char) => {
    const matrix = MATRIX[char] || MATRIX["0"];
    const cols = matrix[0].length;
    const charWidth = cols * dotSize + (cols - 1) * dotGap;
    const startX = acc.currentX;
    const nextX = acc.currentX + charWidth + charGap;
    return {
      items: [...acc.items, { matrix, cols, startX, charWidth }],
      currentX: nextX
    };
  }, { items: [] as { matrix: string[], cols: number, startX: number, charWidth: number }[], currentX: 0 });

  const totalWidthActual = totalWidth - charGap;
  const renderStartX = x - totalWidthActual / 2;

  return (
    <g transform={`translate(${renderStartX}, ${y})`}>
      {charsToRender.map((char, charIdx) => (
        <g key={charIdx} transform={`translate(${char.startX}, 0)`}>
          {char.matrix.map((rowStr, rowIdx) => (
            rowStr.split("").map((cell, colIdx) => (
              <rect
                key={`${rowIdx}-${colIdx}`}
                x={colIdx * (dotSize + dotGap)}
                y={rowIdx * (dotSize + dotGap)}
                width={dotSize}
                height={dotSize}
                rx={1}
                className={cell === "1" ? "dot-active" : "dot-inactive"}
              />
            ))
          ))}
        </g>
      ))}
    </g>
  );
}

export default function CircularGauge({ balance, maxBalance, todaySpend, totalSpend, uptime, isFocused, lang, t }: Props) {
  const now = new Date();

  // ── SVG geometry ──────────────────────────────────────────────
  const SZ = 560;
  const CX = SZ / 2;
  const CY = SZ / 2;

  // Bezel (outermost thick ring)
  const R_BEZ = 265;
  const S_BEZ = 14;

  // Progress arc track
  const R_TRK = 240;
  const S_TRK = 28;

  const ratio = Math.min(Math.max(balance / maxBalance, 0), 1);
  const circum = 2 * Math.PI * R_TRK;
  const filled = circum * ratio;
  const gap = circum - filled;

  // SVG is exactly the dial width — no ruler gutter
  const SVG_W = SZ;
  const SVG_H = SZ;

  // Inner face radius
  const innerR = R_TRK - S_TRK / 2 - 2;

  // ── Outer tick marks — 3 levels ───────────────────────────────
  const TICKS = 120;
  const ticks = Array.from({ length: TICKS }, (_, i) => {
    const ang = (i / TICKS) * 360 - 90;
    const rad = (ang * Math.PI) / 180;
    const isMaj = i % 10 === 0;
    const isMid = i % 5 === 0;
    const r1 = R_BEZ + S_BEZ / 2 + 4;
    const len = isMaj ? 16 : isMid ? 9 : 5;
    return {
      x1: CX + r1 * Math.cos(rad), y1: CY + r1 * Math.sin(rad),
      x2: CX + (r1 + len) * Math.cos(rad), y2: CY + (r1 + len) * Math.sin(rad),
      isMaj, isMid,
    };
  });

  // ── Segmentation lines — 72 radial cuts through arc ──────────
  const SEG_COUNT = 72;
  const segLines = Array.from({ length: SEG_COUNT }, (_, i) => {
    const ang = (i / SEG_COUNT) * 360 - 90;
    const rad = (ang * Math.PI) / 180;
    const r1 = R_TRK - S_TRK / 2 - 1;
    const r2 = R_TRK + S_TRK / 2 + 1;
    return {
      x1: CX + r1 * Math.cos(rad), y1: CY + r1 * Math.sin(rad),
      x2: CX + r2 * Math.cos(rad), y2: CY + r2 * Math.sin(rad),
    };
  });

  // ── Precision red marker on bezel edge ───────────────────────
  const markerAngleDeg = -90 + ratio * 360;
  const markerRad = (markerAngleDeg * Math.PI) / 180;
  const markerR_inner = R_BEZ + S_BEZ / 2 + 6;
  const markerR_outer = markerR_inner + 16;
  const markerLabelR = markerR_outer + 12;
  const mx1 = CX + markerR_inner * Math.cos(markerRad);
  const my1 = CY + markerR_inner * Math.sin(markerRad);
  const mx2 = CX + markerR_outer * Math.cos(markerRad);
  const my2 = CY + markerR_outer * Math.sin(markerRad);
  const mlx = CX + markerLabelR * Math.cos(markerRad);
  const mly = CY + markerLabelR * Math.sin(markerRad);

  // ── Balance string formatting ─────────────────────────────────
  const safeBalance = Number.isFinite(balance) ? balance : 0;
  const balanceText = `¥${safeBalance.toFixed(2)}`;

  return (
    <div style={{
      display: 'flex', flexDirection: 'column',
      alignItems: isFocused ? 'center' : 'flex-start',
      userSelect: 'none', width: '100%',
      transition: 'align-items 0.4s',
    }}>

      {/* ── REC / LIVE capsule ── */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12, marginBottom: isFocused ? 24 : 12,
        padding: '4px 12px 4px 8px', borderRadius: 4,
        border: '1px solid var(--border)',
        background: 'var(--bg-card)',
        boxShadow: '0 1px 4px rgba(0,0,0,0.3)',
        transition: 'margin 0.4s',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span className="rec-pulse" style={{
            display: 'inline-block', width: 6, height: 6, borderRadius: '50%',
            background: 'var(--accent-red)',
            boxShadow: '0 0 4px var(--accent-red-glow)',
          }} />
          <span className="font-num" style={{ fontSize: 9, letterSpacing: '0.2em', color: 'var(--accent-red)', textTransform: 'uppercase', fontWeight: 700 }}>
            REC
          </span>
        </div>
        <div style={{ width: 1, height: 10, background: 'var(--border)' }} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span className="dot-live" />
          <span className="font-num" style={{ fontSize: 9, letterSpacing: lang === 'zh' ? '0.1em' : '0.18em', color: 'var(--text-secondary)', textTransform: 'uppercase', fontWeight: 500 }}>
            {t(lang, 'online')}
          </span>
        </div>
      </div>

      {/* ── SVG Gauge ── */}
      <svg viewBox={`0 0 ${SVG_W} ${SVG_H}`} width={SVG_W} height={SVG_H}
        style={{ overflow: 'visible', maxWidth: '100%', display: 'block' }}>

        <defs>
          <radialGradient id="faceVignette" cx="50%" cy="50%" r="50%">
            <stop offset="60%" stopColor="transparent" />
            <stop offset="100%" stopColor="var(--gauge-vignette)" />
          </radialGradient>
          <radialGradient id="faceLift" cx="50%" cy="40%" r="55%">
            <stop offset="0%" stopColor="var(--gauge-center-mid)" />
            <stop offset="100%" stopColor="var(--gauge-center)" />
          </radialGradient>
          <filter id="segShadow" x="-5%" y="-5%" width="110%" height="110%">
            <feDropShadow dx="0" dy="0" stdDeviation="1.5" floodColor="rgba(0,0,0,0.5)" />
          </filter>
        </defs>

        {/* OUTER BEZEL */}
        <circle cx={CX} cy={CY} r={R_BEZ + S_BEZ + 14}
          fill="none" stroke="var(--gauge-bezel-outer)" strokeWidth={12} />
        <circle cx={CX} cy={CY} r={R_BEZ + S_BEZ + 6}
          fill="none" stroke="var(--gauge-bezel)" strokeWidth={22} />
        <circle cx={CX} cy={CY} r={R_BEZ + S_BEZ / 2 - 2}
          fill="none" stroke="var(--gauge-bezel2)" strokeWidth={1} />
        <path
          d={`M ${CX - (R_BEZ + S_BEZ + 5)} ${CY} A ${R_BEZ + S_BEZ + 5} ${R_BEZ + S_BEZ + 5} 0 0 1 ${CX + (R_BEZ + S_BEZ + 5)} ${CY}`}
          fill="none" stroke="var(--gauge-bezel-hi)" strokeWidth={2}
          strokeLinecap="round" opacity="0.6"
        />

        {/* OUTER TICK MARKS */}
        {ticks.map((t, i) => (
          <line key={i}
            x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2}
            stroke={t.isMaj ? 'var(--gauge-tick-maj)' : t.isMid ? 'var(--gauge-tick-mid)' : 'var(--gauge-tick-min)'}
            strokeWidth={t.isMaj ? 1.5 : t.isMid ? 0.9 : 0.5}
          />
        ))}

        {/* ARC TRACK */}
        <circle cx={CX} cy={CY} r={R_TRK}
          fill="none" stroke="var(--gauge-track)" strokeWidth={S_TRK} />

        {/* FILLED ARC */}
        <circle cx={CX} cy={CY} r={R_TRK}
          fill="none"
          stroke="var(--gauge-arc)"
          strokeWidth={S_TRK}
          strokeDasharray={`${filled} ${gap}`}
          strokeLinecap="butt"
          transform={`rotate(-90 ${CX} ${CY})`}
          style={{ transition: 'stroke-dasharray 0.8s ease' }}
          filter="url(#segShadow)"
        />

        {/* SEGMENTATION LINES */}
        {segLines.map((s, i) => (
          <line key={`seg-${i}`}
            x1={s.x1} y1={s.y1} x2={s.x2} y2={s.y2}
            stroke="var(--gauge-center)" strokeWidth={1.8}
          />
        ))}

        {/* CENTER FACE */}
        <circle cx={CX} cy={CY} r={innerR} fill="url(#faceLift)" />

        {/* INNER RINGS */}
        <circle cx={CX} cy={CY} r={innerR} fill="none" stroke="var(--gauge-inner-ring)" strokeWidth={1.5} />
        <circle cx={CX} cy={CY} r={innerR - 10} fill="none" stroke="var(--gauge-inner-ring)" strokeWidth={0.5} />
        <circle cx={CX} cy={CY} r={innerR - 22} fill="none" stroke="var(--border-subtle)" strokeWidth={0.3} />
        <circle cx={CX} cy={CY} r={innerR - 36} fill="none" stroke="var(--border-subtle)" strokeWidth={0.2} />

        {/* FACE VIGNETTE */}
        <circle cx={CX} cy={CY} r={innerR} fill="url(#faceVignette)" />

        {/* PRECISION BALANCE MARKER */}
        <line x1={mx1} y1={my1} x2={mx2} y2={my2}
          stroke="var(--accent-red)" strokeWidth={1.5}
          style={{ filter: 'drop-shadow(0 0 2px var(--accent-red-glow))' }}
        />
        <circle cx={mx2} cy={my2} r={2.5}
          fill="var(--accent-red)"
          style={{ filter: 'drop-shadow(0 0 3px var(--accent-red-glow))' }}
        />
        <text
          x={mlx} y={mly}
          textAnchor="middle" dominantBaseline="middle"
          style={{ fill: 'var(--accent-red)', fontSize: 9.5, fontFamily: 'ui-monospace,monospace', fontWeight: 700 }}
        >
          {balance.toFixed(0)}
        </text>

        <text x={CX} y={CY - 102} textAnchor="middle"
          className={lang === 'zh' ? 'label-caps zh' : ''}
          style={{ fill: 'var(--text-secondary)', fontSize: 11, fontFamily: 'ui-monospace,monospace', letterSpacing: lang === 'zh' ? 1 : 3, fontWeight: 500 }}>
          {fmtDate(now, lang)}
        </text>

        <text x={CX} y={CY - 78} textAnchor="middle"
          style={{ fill: 'var(--text)', fontSize: 24, fontFamily: 'ui-monospace,monospace', letterSpacing: lang === 'zh' ? 2 : 6, fontWeight: 300 }}>
          {fmtTime(now, lang)}
        </text>

        <text x={CX} y={CY - 50} textAnchor="middle"
          className={`label-caps ${lang === 'zh' ? 'zh' : ''}`}
          style={{ fill: 'var(--text-label)', fontSize: 9.5, fontFamily: 'ui-monospace,monospace', letterSpacing: lang === 'zh' ? 2 : 6, fontWeight: 500 }}>
          {t(lang, 'balanceRemaining')}
        </text>

        {/* Divider */}
        <line x1={CX - 50} y1={CY - 39} x2={CX + 50} y2={CY - 39}
          stroke="var(--gauge-inner-ring)" strokeWidth={1} />

        {/* DOT MATRIX BALANCE NUMBER — Centered SVG components */}
        <DotMatrixNumber text={balanceText} x={CX} y={CY - 28} dotSize={9} dotGap={3} charGap={14} />

        {/* Currency */}
        <text x={CX} y={CY + 84} textAnchor="middle"
          style={{ fill: 'var(--text-label)', fontSize: 11, fontFamily: 'ui-monospace,monospace', letterSpacing: 7, fontWeight: 500 }}>
          CNY
        </text>

        {/* Divider */}
        <line x1={CX - 50} y1={CY + 94} x2={CX + 50} y2={CY + 94}
          stroke="var(--gauge-inner-ring)" strokeWidth={1} />

        <text x={CX - 8} y={CY + 112} textAnchor="end"
          className={`label-caps ${lang === 'zh' ? 'zh' : ''}`}
          style={{ fill: 'var(--text-label)', fontSize: 10, fontFamily: 'ui-monospace,monospace', letterSpacing: lang === 'zh' ? 1 : 3, fontWeight: 500 }}>
          {t(lang, 'today')}
        </text>
        <text x={CX + 8} y={CY + 112} textAnchor="start"
          style={{ fill: 'var(--text-strong)', fontSize: 12, fontFamily: 'ui-monospace,monospace', letterSpacing: 1, fontWeight: 600 }}>
          ¥{todaySpend.toFixed(2)}
        </text>

        <text x={CX - 8} y={CY + 130} textAnchor="end"
          className={`label-caps ${lang === 'zh' ? 'zh' : ''}`}
          style={{ fill: 'var(--text-label)', fontSize: 10, fontFamily: 'ui-monospace,monospace', letterSpacing: lang === 'zh' ? 1 : 3, fontWeight: 500 }}>
          {t(lang, 'total')}
        </text>
        <text x={CX + 8} y={CY + 130} textAnchor="start"
          style={{ fill: 'var(--text-secondary)', fontSize: 12, fontFamily: 'ui-monospace,monospace', letterSpacing: 1, fontWeight: 600 }}>
          ¥{totalSpend.toFixed(2)}
        </text>

        {/* Max Balance Marker (Metadata) */}
        <text x={CX} y={CY + 144} textAnchor="middle"
          className="font-num"
          style={{ fill: 'var(--text-muted)', fontSize: 7.5, letterSpacing: 1, opacity: 0.8 }}>
          MAX {maxBalance} CNY
        </text>

        {/* Bottom marker */}
        <text x={CX} y={CY + 155} textAnchor="middle"
          style={{ fill: 'var(--gauge-inner-ring)', fontSize: 9, fontFamily: 'monospace' }}>
          ▼
        </text>
      </svg>

      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        marginTop: isFocused ? 40 : 24,
        transition: 'margin 0.4s',
      }}>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 11 }}>{t(lang, 'uptime')}</span>
        <span className="font-num" style={{ fontSize: 14, color: 'var(--text-secondary)', letterSpacing: '0.12em', fontWeight: 600 }}>
          {fmtUptime(uptime)}
        </span>
      </div>
    </div>
  );
}
