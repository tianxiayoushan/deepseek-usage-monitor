// src/components/SettingsPanel.tsx
// Settings overlay — Nothing-inspired industrial, matches existing design system
import { useState, useEffect, useCallback } from 'react';
import { X, Save, CheckCircle, AlertCircle, Key } from 'lucide-react';
import type { Language, TranslationFunction } from '../i18n';
import { api } from '../api';
import type { SettingsResponse, SaveSettingsPayload } from '../api';

interface Props {
  onClose: () => void;
  onSaved: () => void; // called after a successful save so parent can re-fetch
  lang: Language;
  t: TranslationFunction;
}

type SaveState = 'idle' | 'saving' | 'ok' | 'error';

export default function SettingsPanel({ onClose, onSaved, lang, t }: Props) {
  const [settings, setSettings] = useState<SettingsResponse | null>(null);
  const [creditInput, setCreditInput] = useState('');
  const [apiKeyInput, setApiKeyInput] = useState('');
  const [saveState, setSaveState] = useState<SaveState>('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const loadSettings = useCallback(async () => {
    const s = await api.getSettings();
    setSettings(s);
    if (s?.initial_total_credit != null) {
      setCreditInput(String(s.initial_total_credit));
    }
  }, []);

  useEffect(() => { loadSettings(); }, [loadSettings]);

  const handleSave = async () => {
    setSaveState('saving');
    setErrorMessage(null);

    const creditVal = creditInput.trim() === '' ? null : parseFloat(creditInput);
    if (creditInput.trim() !== '' && (isNaN(creditVal!) || creditVal! < 0)) {
      setSaveState('error');
      setErrorMessage(t(lang, 'invalidCredit'));
      return;
    }

    const payload: SaveSettingsPayload = { initial_total_credit: creditVal };
    if (apiKeyInput.trim() !== '') {
      payload.deepseek_api_key = apiKeyInput.trim();
    }

    const ok = await api.saveSettings(payload);
    
    if (ok) {
      setSaveState('ok');
      setApiKeyInput(''); // Clear key input after save
      await loadSettings();
      setTimeout(() => {
        setSaveState('idle');
        onSaved();
      }, 900);
    } else {
      setSaveState('error');
      setErrorMessage(t(lang, 'saveError'));
    }
  };

  const backendUnavailable = settings === null;

  return (
    /* Overlay backdrop */
    <div
      id="settings-overlay"
      onClick={(e) => { if ((e.target as HTMLElement).id === 'settings-overlay') onClose(); }}
      style={{
        position: 'fixed', inset: 0,
        background: 'rgba(0,0,0,0.55)',
        backdropFilter: 'blur(3px)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 1000,
      }}
    >
      {/* Panel */}
      <div className="card" style={{
        width: 420,
        padding: '28px 32px 24px',
        position: 'relative',
        borderTop: '2px solid var(--border-strong)',
        background: 'var(--bg-card)',
      }}>

        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 24 }}>
          <div>
            <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 13, letterSpacing: lang === 'zh' ? '0.12em' : '0.32em', color: 'var(--text)', fontWeight: 700 }}>
              {t(lang, 'settings')}
            </div>
            <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 9, letterSpacing: lang === 'zh' ? '0.15em' : '0.4em', color: 'var(--text-muted)', marginTop: 3 }}>
              {t(lang, 'usageMonitor')}
            </div>
          </div>
          <button
            id="settings-close-btn"
            className="theme-toggle"
            onClick={onClose}
            aria-label={t(lang, 'closeSettings')}
            style={{ marginTop: -4 }}
          >
            <X size={14} />
          </button>
        </div>

        <div style={{ height: 1, background: 'var(--border-subtle)', marginBottom: 24 }} />

        {/* Backend unavailable */}
        {backendUnavailable && (
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20,
            padding: '10px 14px',
            background: 'var(--accent-red-glow)',
            border: '1px solid var(--accent-red)',
            borderRadius: 6,
          }}>
            <AlertCircle size={13} color="var(--accent-red)" />
            <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 10, color: 'var(--accent-red)' }}>
              {t(lang, 'backendOffline')}
            </span>
          </div>
        )}

        {/* API Key status */}
        <div style={{ marginBottom: 20 }}>
          <label className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 10, display: 'block', marginBottom: 8 }}>
            {t(lang, 'deepseekApiKey')}
          </label>
          
          {/* Status Badge */}
          <div style={{
            padding: '6px 12px',
            background: 'var(--bg-inset)',
            border: '1px solid var(--border)',
            borderRadius: 6,
            display: 'flex', alignItems: 'center', gap: 8,
            marginBottom: 10
          }}>
            {settings?.api_key_configured ? (
              <>
                <span className="dot-ok" />
                <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 9, color: 'var(--text-secondary)' }}>
                  {t(lang, 'configuredLocally')}
                </span>
              </>
            ) : (
              <>
                <span className="dot-err" />
                <span className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 9, color: 'var(--text-muted)' }}>
                  {t(lang, 'notConfigured')}
                </span>
              </>
            )}
          </div>

          {/* New Key Input */}
          <div style={{ position: 'relative' }}>
            <input
              type="password"
              placeholder={t(lang, 'enterNewApiKey')}
              value={apiKeyInput}
              onChange={(e) => setApiKeyInput(e.target.value)}
              disabled={backendUnavailable}
              style={{
                width: '100%',
                padding: '9px 12px 9px 34px',
                background: 'var(--bg-inset)',
                border: '1px solid var(--border)',
                borderRadius: 6,
                color: 'var(--text)',
                fontFamily: 'ui-monospace, monospace',
                fontSize: 13,
                outline: 'none',
                opacity: backendUnavailable ? 0.4 : 1,
                boxSizing: 'border-box',
              }}
            />
            <Key size={12} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          </div>
          <div className="font-num" style={{ fontSize: 9, color: 'var(--text-muted)', marginTop: 6 }}>
            {t(lang, 'overrideNote')}
          </div>
        </div>

        {/* Initial Total Credit input */}
        <div style={{ marginBottom: 8 }}>
          <label
            htmlFor="initial-credit-input"
            className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`}
            style={{ fontSize: 10, display: 'block', marginBottom: 8 }}
          >
            {t(lang, 'initialTotalCredit')}
          </label>
          <input
            id="initial-credit-input"
            type="number"
            min="0"
            step="0.01"
            placeholder="e.g. 80.00"
            value={creditInput}
            onChange={(e) => setCreditInput(e.target.value)}
            disabled={backendUnavailable}
            style={{
              width: '100%',
              padding: '9px 14px',
              background: 'var(--bg-inset)',
              border: '1px solid var(--border)',
              borderRadius: 6,
              color: 'var(--text)',
              fontFamily: 'ui-monospace, monospace',
              fontSize: 14,
              outline: 'none',
              opacity: backendUnavailable ? 0.4 : 1,
              boxSizing: 'border-box',
            }}
          />
          <div className="font-num" style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 6, lineHeight: 1.5 }}>
            {t(lang, 'creditNote')}
          </div>
        </div>

        {/* Error Message */}
        {errorMessage && (
          <div style={{ color: 'var(--accent-red)', fontSize: 10, marginTop: 8 }} className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`}>
            {errorMessage}
          </div>
        )}

        <div style={{ height: 1, background: 'var(--border-subtle)', margin: '20px 0 20px' }} />

        {/* Save button */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <button
            id="settings-save-btn"
            onClick={handleSave}
            disabled={backendUnavailable || saveState === 'saving'}
            style={{
              display: 'flex', alignItems: 'center', gap: 7,
              padding: '9px 20px',
              background: saveState === 'ok' ? 'var(--accent-green-soft)' : 'var(--bg-card-hover)',
              border: `1px solid ${saveState === 'ok' ? 'var(--accent-green)' : saveState === 'error' ? 'var(--accent-red)' : 'var(--border-strong)'}`,
              borderRadius: 6,
              color: saveState === 'ok' ? 'var(--accent-green)' : saveState === 'error' ? 'var(--accent-red)' : 'var(--text)',
              cursor: backendUnavailable ? 'not-allowed' : 'pointer',
              fontFamily: 'ui-monospace, monospace',
              fontSize: 11,
              letterSpacing: '0.2em',
              textTransform: 'uppercase',
              fontWeight: 600,
              opacity: backendUnavailable ? 0.4 : 1,
              transition: 'all 0.15s',
            }}
          >
            {saveState === 'saving' ? (
              <span>{t(lang, 'saving')}</span>
            ) : saveState === 'ok' ? (
              <><CheckCircle size={12} /><span>{t(lang, 'saved')}</span></>
            ) : saveState === 'error' ? (
              <><AlertCircle size={12} /><span>{t(lang, 'saveError')}</span></>
            ) : (
              <><Save size={12} /><span>{t(lang, 'save')}</span></>
            )}
          </button>

          {/* Estimation preview */}
          {settings?.initial_total_credit != null && settings?.api_key_configured && (
            <span className="font-num" style={{ fontSize: 10, color: 'var(--text-muted)' }}>
              spend = {settings.initial_total_credit.toFixed(2)} − balance
            </span>
          )}
        </div>

        {/* Footer note */}
        <div style={{ marginTop: 20 }}>
          <div className={`font-num label-caps ${lang === 'zh' ? 'zh' : ''}`} style={{ fontSize: 9, color: 'var(--text-muted)', lineHeight: 1.6 }}>
            {t(lang, 'estimateNote')}
          </div>
        </div>
      </div>
    </div>
  );
}
