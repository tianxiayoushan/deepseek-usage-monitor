// src/components/ModelUsage.tsx — compact row layout
import type { Language, TranslationFunction } from '../i18n';
import type { ModelUsageData } from '../mockData';

interface Props {
  models: ModelUsageData[];
  lang: Language;
  t: TranslationFunction;
}

function fmtTok(n: number) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(2)}M`;
  if (n >= 1_000)     return `${(n / 1_000).toFixed(0)}K`;
  return String(n);
}

function ThinBar({ pct, segs = 24 }: { pct: number; segs?: number }) {
  const filled = Math.round((pct / 100) * segs);
  return (
    <div style={{ display:'flex', gap:2, marginTop:10 }}>
      {Array.from({ length: segs }, (_, i) => (
        <div key={i} style={{
          flex:1, height:4, borderRadius:1,
          background: i < filled ? 'var(--text)' : 'var(--border-subtle)',
          opacity: i < filled ? 0.75 : 0.6,
        }} />
      ))}
    </div>
  );
}

export default function ModelUsage({ models, lang, t }: Props) {
  return (
    <div className="card" style={{ padding:'18px 22px' }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:10 }}>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:11 }}>{t(lang, 'modelUsageToday')}</span>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:9, color:'var(--text-label)' }}>
          {new Date().toLocaleDateString(lang === 'zh' ? 'zh-CN' : 'en-US', { month:'short', day:'numeric' })}
        </span>
      </div>

      <div style={{ display:'flex', flexDirection:'column' }}>
        {models.map((m, idx) => {
          const isPro = m.name.includes('pro');
          return (
            <div key={m.name}>
              {idx > 0 && <div style={{ height:1, background:'var(--border-subtle)', margin:'14px 0' }} />}

              <div style={{ display:'flex', alignItems:'baseline', gap:10 }}>
                <span className="font-num" style={{
                  fontSize:9, letterSpacing:'0.12em', textTransform:'uppercase',
                  padding:'1px 6px', borderRadius:2, flexShrink:0,
                  border:`1px solid ${isPro ? 'var(--accent-blue)' : 'var(--border-strong)'}`,
                  color: isPro ? 'var(--accent-blue)' : 'var(--text-secondary)', fontWeight:700,
                }}>
                  {isPro ? 'PRO' : 'FLASH'}
                </span>

                <span className="font-num" style={{
                  fontSize:14, fontWeight:600, color:'var(--text)',
                  flex:1, minWidth:0, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap',
                }}>
                  {m.name}
                </span>

                <div style={{ display:'flex', gap:14, flexShrink:0 }}>
                  {[
                    { label: t(lang, 'time').slice(0, 3).toUpperCase(), value: String(m.requests), key: 'requests' },
                    { label: t(lang, 'total_tokens').toUpperCase(), value: fmtTok(m.totalTokens), key: 'tokens' },
                    { label: t(lang, 'cost').toUpperCase(),   value: `¥${m.estimatedCost.toFixed(2)}`, key: 'cost' },
                    { label: 'SHARE',  value: `${m.percentage}%`, key: 'share' },
                  ].map(cell => (
                    <div key={cell.key} style={{ textAlign:'right' }}>
                      <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:9, color:'var(--text-label)' }}>{cell.label}</div>
                      <div className="font-num" style={{ fontSize:15, fontWeight:700, color:'var(--text-strong)' }}>{cell.value}</div>
                    </div>
                  ))}
                </div>
              </div>

              <ThinBar pct={m.percentage} />
            </div>
          );
        })}
      </div>
    </div>
  );
}
