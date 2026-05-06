// src/components/MetricCard.tsx
// Industrial metric card — strong borders, clear hierarchy, monochrome
import type { Language } from '../i18n';
import type { ReactNode } from 'react';

interface Props {
  label: string;
  value: string;
  sub?: string;
  accent?: 'white' | 'red' | 'blue';
  icon?: ReactNode;
  lang?: Language;
}

export default function MetricCard({ label, value, sub, accent = 'white', icon, lang }: Props) {
  const isRed = accent === 'red';

  return (
    <div className={`card accent-${accent}`} style={{
      padding: '16px 20px 14px',
      position: 'relative',
      overflow: 'hidden',
      minHeight: 108,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      borderTop: '2px solid',
    }}>
      {/* Label row */}
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: 8 }}>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 11 }}>
          {label}
        </span>
        {icon && <span style={{ color:'var(--text-muted)' }}>{icon}</span>}
      </div>

      {/* Value — display level */}
      <div className="font-num" style={{
        fontSize: 42,
        fontWeight: 700,
        lineHeight: 1,
        color: isRed ? 'var(--accent-red)' : 'var(--text-strong)',
        letterSpacing: '-0.02em',
      }}>
        {value}
      </div>

      {sub && (
        <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 10, marginTop: 6, color:'var(--text-label)' }}>
          {sub}
        </div>
      )}
    </div>
  );
}
