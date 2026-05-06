// src/components/RecentRequests.tsx — 4 rows max, compact, no clipping
import type { RequestRecord } from '../mockData';
interface Props {
  requests: RequestRecord[];
  lang: any;
  t: any;
}

function fmtTime(iso: string) {
  return new Date(iso).toLocaleTimeString('en-US',{ hour:'2-digit', minute:'2-digit', second:'2-digit', hour12:false });
}
function fmtTok(n: number) {
  if (n >= 1_000_000) return `${(n/1_000_000).toFixed(1)}M`;
  if (n >= 1_000)     return `${(n/1_000).toFixed(0)}K`;
  return String(n);
}
function fmtLat(ms: number) { return ms >= 1000 ? `${(ms/1000).toFixed(1)}s` : `${ms}ms`; }

const MODEL_LABEL: Record<string,string> = {
  'deepseek-v4-flash': 'FLASH',
  'deepseek-v4-pro':   'PRO',
};

export default function RecentRequests({ requests, lang, t }: Props) {
  const rows = requests.slice(0, 5);
  const cols = [
    { key: 'time', label: t(lang, 'time') },
    { key: 'model', label: t(lang, 'model') },
    { key: 'prompt', label: t(lang, 'prompt') },
    { key: 'comp', label: t(lang, 'comp') },
    { key: 'total', label: t(lang, 'total_tokens') },
    { key: 'cost', label: t(lang, 'cost') },
    { key: 'status', label: t(lang, 'status') },
    { key: 'latency', label: t(lang, 'latency') },
  ];

  return (
    <div className="card" style={{ overflow:'hidden', display:'flex', flexDirection:'column' }}>
      {/* Header */}
      <div style={{
        display:'flex', justifyContent:'space-between', alignItems:'center',
        padding:'10px 16px 8px', borderBottom:'1px solid var(--border)', flexShrink:0,
      }}>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:11 }}>{t(lang, 'recentRequests')}</span>
        <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize:10, color:'var(--text-label)' }}>{t(lang, 'last5')}</span>
      </div>

      {/* Table — fixed, no overflow */}
      <div style={{ flexShrink:0 }}>
        <table style={{ width:'100%', borderCollapse:'collapse', fontFamily:'ui-monospace,monospace', fontSize:12 }}>
          <thead>
            <tr>
              {cols.map(c => (
                <th key={c.key} className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{
                  padding:'10px 12px', textAlign:'left', fontWeight:600,
                  color:'var(--text-label)', fontSize:10,
                  letterSpacing: lang === 'zh' ? '0.08em' : '0.16em',
                  textTransform: 'uppercase',
                  borderBottom:'1px solid var(--border)', whiteSpace:'nowrap',
                }}>{c.label}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((r, idx) => {
              const isPro = r.model.includes('pro');
              const latColor = r.latencyMs > 5000 ? 'var(--accent-red)'
                : r.latencyMs > 1500 ? 'var(--text-muted)' : 'var(--text-secondary)';
              return (
                <tr key={r.id} style={{
                  borderBottom: idx < rows.length - 1 ? '1px solid var(--border-subtle)' : 'none',
                  background: idx % 2 === 1 ? 'var(--bg-inset)' : 'transparent',
                }}>
                  <td style={{ padding:'10px 12px', color:'var(--text-secondary)', whiteSpace:'nowrap' }}>{fmtTime(r.timestamp)}</td>
                  <td style={{ padding:'10px 12px', whiteSpace:'nowrap' }}>
                    <span style={{
                      padding:'1px 7px', borderRadius:3, fontSize:10,
                      letterSpacing:'0.08em', fontWeight:700,
                      border:`1px solid ${isPro ? 'var(--accent-blue)' : 'var(--border-strong)'}`,
                      color: isPro ? 'var(--accent-blue)' : 'var(--text-secondary)',
                    }}>
                      {MODEL_LABEL[r.model] ?? r.model}
                    </span>
                  </td>
                  <td style={{ padding:'10px 12px', textAlign:'right', color:'var(--text-secondary)', whiteSpace:'nowrap' }}>{fmtTok(r.promptTokens)}</td>
                  <td style={{ padding:'10px 12px', textAlign:'right', color:'var(--text-secondary)', whiteSpace:'nowrap' }}>{fmtTok(r.completionTokens)}</td>
                  <td style={{ padding:'10px 12px', textAlign:'right', color:'var(--text-strong)', fontWeight:700, whiteSpace:'nowrap' }}>{fmtTok(r.totalTokens)}</td>
                  <td style={{ padding:'10px 12px', textAlign:'right', color:'var(--text-secondary)', whiteSpace:'nowrap' }}>¥{r.estimatedCost.toFixed(4)}</td>
                  <td style={{ padding:'10px 12px', whiteSpace:'nowrap' }}>
                    <div style={{ display:'flex', alignItems:'center', gap:5 }}>
                      <span className={r.status === 'success' ? 'dot-ok' : 'dot-err'} />
                      <span style={{ fontSize:10, fontWeight:600, letterSpacing:'0.08em',
                        color: r.status === 'success' ? 'var(--accent-green)' : 'var(--accent-red)' }}>
                        {(r.status === 'success' ? t(lang, 'success') : t(lang, 'error')).toUpperCase()}
                      </span>
                    </div>
                  </td>
                  <td style={{ padding:'10px 12px', textAlign:'right', color: latColor, whiteSpace:'nowrap', fontWeight:600 }}>{fmtLat(r.latencyMs)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
