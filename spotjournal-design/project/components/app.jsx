// SpotJournal — top-level app
// Phone frame + screen router + tweak panel.

// Tweakable defaults — the host rewrites this when the user sets knobs.
const TWEAKS = /*EDITMODE-BEGIN*/{
  "layout": "classic",
  "theme": "light",
  "captionFont": "serif"
}/*EDITMODE-END*/;

// ── persistence ──────────────────────────────────────────────
const STORAGE_KEY = 'spotjournal.v1';

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (parsed.entries) parsed.entries = parsed.entries.map(e => ({ ...e, date: new Date(e.date) }));
    return parsed;
  } catch { return null; }
}
function saveState(s) {
  try {
    const payload = { ...s, entries: s.entries.map(e => ({ ...e, date: e.date.toISOString() })) };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch {}
}

const PHOTO_CYCLE = ['plate', 'trail', 'window', 'coffee'];

// ── App ──────────────────────────────────────────────────────
function App() {
  const saved = loadState();

  const [theme, setTheme] = React.useState(saved?.theme || TWEAKS.theme);
  const [captionFont, setCaptionFont] = React.useState(saved?.captionFont || TWEAKS.captionFont);
  const [layout, setLayout] = React.useState(TWEAKS.layout);
  const [name, setName] = React.useState(saved?.name || '');
  const [entries, setEntries] = React.useState(saved?.entries || sampleEntries);

  const [screen, setScreen] = React.useState('home'); // home | browse | camera | review | saved | entry
  const [viewingEntry, setViewingEntry] = React.useState(null);
  const [mode, setMode] = React.useState('photo');
  const [pendingPhoto, setPendingPhoto] = React.useState(null);
  const [pendingDate, setPendingDate] = React.useState(null);
  const [pendingPlace] = React.useState('Cobble Hill, Brooklyn');
  const [settingsOpen, setSettingsOpen] = React.useState(false);
  const [tweaksVisible, setTweaksVisible] = React.useState(false);

  React.useEffect(() => {
    saveState({ theme, captionFont, name, entries });
  }, [theme, captionFont, name, entries]);

  React.useEffect(() => {
    document.body.classList.toggle('theme-dark', theme === 'dark');
    document.body.classList.toggle('theme-light', theme !== 'dark');
  }, [theme]);

  React.useEffect(() => {
    const onMsg = (e) => {
      const d = e.data;
      if (!d || !d.type) return;
      if (d.type === '__activate_edit_mode') setTweaksVisible(true);
      if (d.type === '__deactivate_edit_mode') setTweaksVisible(false);
    };
    window.addEventListener('message', onMsg);
    window.parent.postMessage({ type: '__edit_mode_available' }, '*');
    return () => window.removeEventListener('message', onMsg);
  }, []);

  const latest = entries[0];

  const openCamera = () => setScreen('camera');
  const cancelCamera = () => setScreen('home');
  const openBrowse = () => setScreen('browse');

  const capture = () => {
    const nextIdx = entries.length % PHOTO_CYCLE.length;
    setPendingPhoto(PHOTO_CYCLE[nextIdx]);
    setPendingDate(new Date());
    setScreen('review');
  };

  const cancelReview = () => {
    setPendingPhoto(null);
    setScreen('camera');
  };

  const savePage = (caption) => {
    const entry = {
      id: 'e-' + Date.now(),
      photoKey: pendingPhoto,
      caption: caption || '—',
      date: pendingDate || new Date(),
      place: pendingPlace,
    };
    setEntries(es => [entry, ...es]);
    setScreen('saved');
    setPendingPhoto(null);
    setTimeout(() => setScreen('home'), 1400);
  };

  const openEntry = (e) => {
    setViewingEntry(e);
    setScreen('entry');
  };

  const setLayoutT = (v) => { setLayout(v); window.parent.postMessage({ type: '__edit_mode_set_keys', edits: { layout: v } }, '*'); };
  const setThemeT = (v) => { setTheme(v); window.parent.postMessage({ type: '__edit_mode_set_keys', edits: { theme: v } }, '*'); };
  const setFontT = (v) => { setCaptionFont(v); window.parent.postMessage({ type: '__edit_mode_set_keys', edits: { captionFont: v } }, '*'); };

  let body;
  if (screen === 'camera') {
    body = <CameraScreen mode={mode} onMode={setMode} onCancel={cancelCamera} onCapture={capture}/>;
  } else if (screen === 'review') {
    body = <ReviewScreen
      capturedPhotoKey={pendingPhoto}
      captionFont={captionFont}
      now={pendingDate || new Date()}
      place={pendingPlace}
      onCancel={cancelReview}
      onSave={savePage}
    />;
  } else if (screen === 'browse') {
    body = <BrowseScreen
      entries={entries}
      onBack={() => setScreen('home')}
      onOpen={openEntry}
      onSettings={() => setSettingsOpen(true)}
    />;
  } else if (screen === 'entry' && viewingEntry) {
    body = <EntryViewer
      entry={viewingEntry}
      layout={layout}
      captionFont={captionFont}
      onBack={() => setScreen('browse')}
    />;
  } else {
    body = <HomePage
      entry={latest}
      layout={layout}
      captionFont={captionFont}
      name={name}
      justSaved={screen === 'saved'}
      onShoot={openCamera}
      onBrowse={openBrowse}
      onSettings={() => setSettingsOpen(true)}
    />;
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--bg-alt)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 32, boxSizing: 'border-box',
    }}>
      <div style={{ position: 'relative' }}>
        <IOSDevice dark={theme === 'dark'}>
          <div style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
            {body}
          </div>
          <SettingsSheet
            open={settingsOpen}
            theme={theme}
            onClose={() => setSettingsOpen(false)}
            name={name}
            onName={setName}
            captionFont={captionFont}
            onCaptionFont={setFontT}
            onToggleTheme={() => setThemeT(theme === 'dark' ? 'light' : 'dark')}
          />
        </IOSDevice>
      </div>

      {tweaksVisible && (
        <TweaksPanel
          layout={layout} onLayout={setLayoutT}
          theme={theme} onTheme={setThemeT}
          captionFont={captionFont} onCaptionFont={setFontT}
        />
      )}
    </div>
  );
}

// ── Home — latest entry w/ app header + FAB. Swipe left → browse ──
function HomePage({ entry, layout, captionFont, name, justSaved, onShoot, onBrowse, onSettings }) {
  // Swipe-left gesture
  const startX = React.useRef(null);
  const onPointerDown = (e) => { startX.current = e.clientX; };
  const onPointerUp = (e) => {
    if (startX.current == null) return;
    const dx = e.clientX - startX.current;
    if (dx < -60) onBrowse();
    startX.current = null;
  };

  return (
    <div
      onPointerDown={onPointerDown}
      onPointerUp={onPointerUp}
      style={{ position: 'absolute', inset: 0, overflow: 'hidden', touchAction: 'pan-y' }}
    >
      {/* page */}
      <div style={{ position: 'absolute', inset: 0 }}>
        <JournalPage entry={entry} layout={layout} captionFont={captionFont}/>
      </div>

      {/* App header — sits in the paper, below iOS status bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0,
        paddingTop: 58, paddingLeft: 14, paddingRight: 14, paddingBottom: 8,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        zIndex: 40,
        pointerEvents: 'none',
      }}>
        <div style={{ pointerEvents: 'auto' }}>
          <button className="icon-chip" onClick={onBrowse}>
            <Icon name="grid" size={17}/>
          </button>
        </div>

        <div className="typeset" style={{
          fontSize: 11, color: 'var(--fg-3)', letterSpacing: 0.2,
          pointerEvents: 'none',
        }}>
          {name ? `${name}'s journal` : 'today'}
        </div>

        <div style={{ pointerEvents: 'auto' }}>
          <button className="icon-chip" onClick={onSettings}>
            <Icon name="settings" size={17}/>
          </button>
        </div>
      </div>

      {/* swipe-left affordance */}
      <div style={{
        position: 'absolute', right: 10, top: '50%',
        transform: 'translateY(-50%)', zIndex: 30,
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        color: 'var(--fg-4)', pointerEvents: 'none',
      }}>
        <Icon name="chevron-right" size={14}/>
        <div className="typeset" style={{ fontSize: 9, letterSpacing: 0.3, writingMode: 'vertical-rl' }}>
          swipe for more
        </div>
      </div>

      {/* saved toast */}
      {justSaved && (
        <div style={{
          position: 'absolute', top: 110, left: '50%', transform: 'translateX(-50%)',
          zIndex: 80,
          background: 'var(--fg-1)', color: 'var(--bg)',
          padding: '10px 16px', borderRadius: 999,
          fontSize: 13, fontWeight: 500,
          display: 'flex', alignItems: 'center', gap: 6,
          boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
          animation: 'fadeIn 200ms var(--ease-standard)',
        }}>
          <Icon name="check" size={14}/>
          Saved.
        </div>
      )}

      {/* FAB */}
      <div style={{
        position: 'absolute', bottom: 46, left: 0, right: 0,
        display: 'flex', justifyContent: 'center',
        zIndex: 50,
      }}>
        <div className="fab" onClick={onShoot}>
          <Icon name="camera" size={28}/>
        </div>
      </div>
    </div>
  );
}

const iconChipStyle = {
  width: 36, height: 36, borderRadius: 999,
  background: 'rgba(250, 247, 240, 0.72)',
  backdropFilter: 'blur(10px)',
  WebkitBackdropFilter: 'blur(10px)',
  border: '1px solid rgba(140, 110, 60, 0.14)',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  cursor: 'pointer', color: 'var(--fg-1)', padding: 0,
};

// ── Entry viewer (opened from browse) — reuses JournalPage ──
function EntryViewer({ entry, layout, captionFont, onBack }) {
  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <JournalPage entry={entry} layout={layout} captionFont={captionFont}/>
      </div>
      <div style={{
        position: 'absolute', top: 58, left: 14, zIndex: 40,
      }}>
        <button className="icon-chip" onClick={onBack}>
          <Icon name="chevron-left" size={17}/>
        </button>
      </div>
    </div>
  );
}

// ── Tweaks panel (bottom-right floating card, outside the phone) ──
function TweaksPanel({ layout, onLayout, theme, onTheme, captionFont, onCaptionFont }) {
  const Btn = ({ active, onClick, children }) => (
    <button onClick={onClick} style={{
      padding: '7px 12px', borderRadius: 999,
      border: `1px solid ${active ? 'var(--accent)' : 'var(--border-1)'}`,
      background: active ? 'var(--accent-soft)' : 'var(--surface)',
      color: active ? 'var(--accent)' : 'var(--fg-1)',
      fontFamily: 'var(--font-sans)', fontSize: 12, fontWeight: 600,
      cursor: 'pointer', letterSpacing: -0.1,
    }}>{children}</button>
  );
  return (
    <div style={{
      position: 'fixed', bottom: 20, right: 20,
      background: 'var(--surface)',
      border: '1px solid var(--border-1)',
      borderRadius: 14,
      boxShadow: 'var(--shadow-lg)',
      padding: 14,
      width: 240,
      fontFamily: 'var(--font-sans)',
      zIndex: 999,
    }}>
      <div className="h2" style={{ fontSize: 16, marginBottom: 10 }}>Tweaks</div>

      <div style={{ marginBottom: 12 }}>
        <div className="overline" style={{ fontSize: 10, marginBottom: 6 }}>Entry layout</div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {Object.entries(LAYOUTS).map(([k, v]) => (
            <Btn key={k} active={layout === k} onClick={() => onLayout(k)}>{v.name}</Btn>
          ))}
        </div>
        <div className="caption" style={{ fontSize: 11, marginTop: 6, color: 'var(--fg-3)' }}>
          {LAYOUTS[layout].blurb}
        </div>
      </div>

      <div style={{ marginBottom: 12 }}>
        <div className="overline" style={{ fontSize: 10, marginBottom: 6 }}>Caption</div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn active={captionFont === 'serif'} onClick={() => onCaptionFont('serif')}>Typeset</Btn>
          <Btn active={captionFont === 'sans'}  onClick={() => onCaptionFont('sans')}>Plain</Btn>
          <Btn active={captionFont === 'hand'}  onClick={() => onCaptionFont('hand')}>Written</Btn>
        </div>
      </div>

      <div>
        <div className="overline" style={{ fontSize: 10, marginBottom: 6 }}>Theme</div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn active={theme === 'light'} onClick={() => onTheme('light')}>Light</Btn>
          <Btn active={theme === 'dark'}  onClick={() => onTheme('dark')}>Dark</Btn>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { App });
