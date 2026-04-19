// SpotJournal — settings sheet.
// Export/rename + caption typeface picker (with live preview).
// Exports: SettingsSheet.

function SettingsSheet({ open, theme, onClose, name, onName, captionFont, onCaptionFont, onToggleTheme }) {
  const [draft, setDraft] = React.useState(name);
  React.useEffect(() => { setDraft(name); }, [name, open]);

  if (!open) return null;

  const cardBg = 'var(--surface)';
  const pageBg = 'var(--bg)';

  const FONTS = [
    { id: 'serif', label: 'Typeset', sample: 'The morning was quiet.', className: 'ink-serif' },
    { id: 'sans',  label: 'Plain',   sample: 'The morning was quiet.', className: 'ink-sans' },
    { id: 'hand',  label: 'Written', sample: 'The morning was quiet.', className: 'ink-hand' },
  ];

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* scrim */}
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0,
        background: 'var(--scrim)',
        animation: 'fadeIn 180ms var(--ease-standard)',
      }}/>
      {/* sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: pageBg,
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        maxHeight: '85%', display: 'flex', flexDirection: 'column',
        boxShadow: '0 -12px 40px rgba(0,0,0,0.25)',
        animation: 'slideUp 240ms var(--ease-emphasized)',
        overflow: 'hidden',
      }}>
        {/* grabber */}
        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 10, paddingBottom: 4 }}>
          <div style={{ width: 40, height: 4, borderRadius: 2, background: 'var(--border-2)' }}/>
        </div>

        {/* header */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '12px 20px 8px',
        }}>
          <div className="h2" style={{ margin: 0 }}>Settings</div>
          <button onClick={onClose} style={{
            width: 32, height: 32, borderRadius: 999, border: 0,
            background: 'var(--surface-sunken)', color: 'var(--fg-1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}><Icon name="close" size={16}/></button>
        </div>

        <div style={{ overflow: 'auto', padding: '8px 20px 24px' }}>
          {/* Name */}
          <div style={{ marginBottom: 22 }}>
            <div className="overline" style={{ marginBottom: 8 }}>Your name</div>
            <input
              className="input"
              value={draft}
              onChange={e => setDraft(e.target.value)}
              onBlur={() => onName(draft)}
              placeholder="Leave blank to stay anonymous"
              style={{
                background: cardBg,
                fontSize: 16,
              }}
            />
            <div className="caption" style={{ marginTop: 6 }}>
              Stays on this device. Always.
            </div>
          </div>

          {/* Caption typeface */}
          <div style={{ marginBottom: 22 }}>
            <div className="overline" style={{ marginBottom: 8 }}>Caption typeface</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {FONTS.map(f => (
                <button key={f.id} onClick={() => onCaptionFont(f.id)} style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  gap: 12,
                  background: cardBg,
                  border: `1px solid ${captionFont === f.id ? 'var(--accent)' : 'var(--border-1)'}`,
                  borderRadius: 12,
                  padding: '14px 16px',
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'border-color 120ms',
                }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 0 }}>
                    <div className="body-sm" style={{ fontWeight: 600, color: 'var(--fg-1)' }}>{f.label}</div>
                    <div className={f.className} style={{
                      fontSize: f.id === 'hand' ? 22 : 16,
                      color: 'var(--fg-2)',
                      lineHeight: 1.2,
                      whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                    }}>{f.sample}</div>
                  </div>
                  <div style={{
                    width: 20, height: 20, borderRadius: 999,
                    border: `2px solid ${captionFont === f.id ? 'var(--accent)' : 'var(--border-2)'}`,
                    background: captionFont === f.id ? 'var(--accent)' : 'transparent',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0,
                  }}>
                    {captionFont === f.id && <Icon name="check" size={12} stroke="#fff"/>}
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Theme */}
          <div style={{ marginBottom: 22 }}>
            <div className="overline" style={{ marginBottom: 8 }}>Appearance</div>
            <button onClick={onToggleTheme} style={{
              width: '100%',
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              background: cardBg,
              border: '1px solid var(--border-1)',
              borderRadius: 12, padding: '14px 16px',
              cursor: 'pointer', textAlign: 'left',
            }}>
              <div>
                <div className="body-sm" style={{ fontWeight: 600, color: 'var(--fg-1)' }}>
                  {theme === 'dark' ? 'Dark' : 'Light'}
                </div>
                <div className="caption">Tap to switch</div>
              </div>
              <div style={{
                width: 44, height: 26, borderRadius: 999,
                background: theme === 'dark' ? 'var(--accent)' : 'var(--border-2)',
                position: 'relative', transition: 'background 180ms',
              }}>
                <div style={{
                  width: 20, height: 20, borderRadius: 999, background: '#fff',
                  position: 'absolute', top: 3, left: theme === 'dark' ? 21 : 3,
                  transition: 'left 180ms var(--ease-standard)',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                }}/>
              </div>
            </button>
          </div>

          {/* Export */}
          <div style={{ marginBottom: 22 }}>
            <div className="overline" style={{ marginBottom: 8 }}>Your journal</div>
            <button className="btn btn-secondary" style={{
              width: '100%', justifyContent: 'space-between', padding: '14px 16px',
              borderRadius: 12, fontSize: 15, fontWeight: 600,
            }}>
              <span>Export</span>
              <Icon name="chevron-right" size={16}/>
            </button>
            <div className="caption" style={{ marginTop: 6 }}>
              A zip with every photo and page, saved to your device.
            </div>
          </div>

          {/* About footer */}
          <div style={{
            padding: '16px 0 4px', textAlign: 'center',
          }}>
            <div className="typeset ink-3" style={{ fontSize: 10 }}>
              SpotJournal · v1.0
            </div>
            <div className="caption" style={{ marginTop: 4 }}>
              Nothing leaves this phone.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SettingsSheet });
