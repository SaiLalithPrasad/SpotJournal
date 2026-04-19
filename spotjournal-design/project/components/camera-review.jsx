// SpotJournal — camera viewfinder and review/write screens.
// Exports: CameraScreen, ReviewScreen.

function CameraScreen({ onCancel, onCapture, mode, onMode }) {
  const [flash, setFlash] = React.useState(false);
  const [recording, setRecording] = React.useState(false);
  const [shutterFlash, setShutterFlash] = React.useState(false);

  const shoot = () => {
    if (mode === 'video') {
      setRecording(r => !r);
      if (recording) onCapture();
      return;
    }
    setShutterFlash(true);
    setTimeout(() => {
      setShutterFlash(false);
      onCapture();
    }, 160);
  };

  const white = 'rgba(255,255,255,0.85)';
  const whiteDim = 'rgba(255,255,255,0.55)';

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: '#000',
      display: 'flex', flexDirection: 'column',
      fontFamily: '-apple-system, system-ui',
    }}>
      {/* Viewfinder image */}
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
        {PLACEHOLDER_PHOTOS.viewfinder}
        {/* subtle vignette */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(ellipse at center, transparent 55%, rgba(0,0,0,0.35) 100%)',
        }}/>
      </div>

      {/* Shutter flash */}
      {shutterFlash && (
        <div style={{
          position: 'absolute', inset: 0, background: '#fff',
          opacity: 0.85, zIndex: 30, pointerEvents: 'none',
        }}/>
      )}

      {/* Top bar — close + flash */}
      <div style={{
        position: 'relative', zIndex: 10,
        padding: '60px 20px 0',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <button onClick={onCancel} style={iconBtnStyle}>
          <Icon name="close" size={22} stroke="#fff"/>
        </button>
        <div style={{
          background: 'rgba(0,0,0,0.32)', color: '#fff',
          padding: '6px 12px', borderRadius: 999,
          fontSize: 13, fontWeight: 500, letterSpacing: 0.2,
        }}>
          {recording ? <><span style={{
            display: 'inline-block', width: 8, height: 8, borderRadius: 4,
            background: '#E0373A', marginRight: 6, verticalAlign: 'middle',
            animation: 'blink 1s steps(2) infinite',
          }}/>REC</> : 'Tap to capture'}
        </div>
        <button onClick={() => setFlash(f => !f)} style={iconBtnStyle}>
          <Icon name={flash ? 'flash' : 'flash-off'} size={20} stroke={flash ? '#FFD882' : '#fff'}/>
        </button>
      </div>

      <div style={{ flex: 1 }}/>

      {/* Bottom controls */}
      <div style={{
        position: 'relative', zIndex: 10,
        padding: '0 24px 56px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
      }}>
        {/* mode toggle */}
        <div style={{
          display: 'flex', gap: 4,
          background: 'rgba(0,0,0,0.35)', borderRadius: 999,
          padding: 3, marginBottom: 28,
        }}>
          {['photo','video'].map(m => (
            <button key={m} onClick={() => onMode(m)} style={{
              padding: '7px 16px', borderRadius: 999, border: 0,
              background: mode === m ? 'rgba(255,255,255,0.95)' : 'transparent',
              color: mode === m ? '#000' : white,
              fontSize: 13, fontWeight: 600, letterSpacing: 0.3,
              cursor: 'pointer',
              textTransform: 'uppercase',
              fontFamily: 'inherit',
            }}>{m}</button>
          ))}
        </div>

        {/* shutter row */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          width: '100%',
        }}>
          {/* small preview chip (placeholder) */}
          <div style={{
            width: 40, height: 40, borderRadius: 8,
            border: '1.5px solid rgba(255,255,255,0.6)',
            background: 'rgba(40,25,15,0.6)',
          }}/>

          <div className={'shutter' + (recording ? ' recording' : '')} onClick={shoot}/>

          <button style={{ ...iconBtnStyle, width: 40, height: 40 }}>
            <Icon name="flip" size={20} stroke="#fff"/>
          </button>
        </div>
      </div>
    </div>
  );
}

const iconBtnStyle = {
  width: 38, height: 38, borderRadius: 999,
  background: 'rgba(0,0,0,0.35)',
  border: 0,
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  cursor: 'pointer',
  padding: 0,
};


// ── Review screen: photo is being "pasted" onto a fresh page.
// User types their caption. Timestamp + location appear automatically.
function ReviewScreen({ capturedPhotoKey, captionFont, now, place, onCancel, onSave }) {
  const [caption, setCaption] = React.useState('');
  const font = captionFont === 'sans' ? 'ink-sans' : captionFont === 'hand' ? 'ink-hand' : 'ink-serif';
  const placeholder = "Write a few words about this moment…";

  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column' }}>
      <div className="paper paper-edge" style={{
        flex: 1,
        padding: '68px 20px 24px',
        display: 'flex', flexDirection: 'column',
        overflow: 'hidden',
      }}>
        {/* top bar over paper */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          marginBottom: 14, gap: 8,
        }}>
          <button onClick={onCancel} style={pageBtnStyle('secondary')}>
            <Icon name="retake" size={14}/>
            <span>Retake</span>
          </button>
          <div className="typeset ink-3" style={{ fontSize: 10, whiteSpace: 'nowrap' }}>new entry</div>
          <button
            onClick={() => onSave(caption.trim() || '')}
            style={pageBtnStyle('primary')}
          >
            <Icon name="check" size={14}/>
            <span>Paste</span>
          </button>
        </div>

        {/* the photo, freshly taped */}
        <div style={{ margin: '12px 0 20px' }}>
          <PhotoPaste photoKey={capturedPhotoKey} width={244} height={288} rotate={-1.4}/>
        </div>

        {/* caption input — styled to look like writing on the page */}
        <textarea
          className={font + ' ink-1'}
          value={caption}
          onChange={e => setCaption(e.target.value)}
          placeholder={placeholder}
          autoFocus
          style={{
            flex: 1,
            minHeight: 80,
            border: 0,
            background: 'transparent',
            resize: 'none',
            outline: 'none',
            fontSize: captionFont === 'hand' ? 26 : 19,
            lineHeight: captionFont === 'hand' ? 1.25 : 1.55,
            letterSpacing: -0.005,
            textAlign: 'center',
            padding: '4px 4px',
          }}
        />

        {/* auto timestamp */}
        <div style={{ marginTop: 16 }}>
          <PageTimestamp date={now} place={place} align="center"/>
        </div>
      </div>
    </div>
  );
}

function pageBtnStyle(kind) {
  if (kind === 'primary') return {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    background: 'var(--accent)', color: 'var(--fg-on-accent)',
    border: 0, borderRadius: 999, padding: '8px 16px',
    fontFamily: 'var(--font-sans)', fontSize: 13, fontWeight: 600,
    cursor: 'pointer', letterSpacing: -0.1, whiteSpace: 'nowrap',
    flexShrink: 0,
  };
  return {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    background: 'transparent', color: 'var(--fg-2)',
    border: 0, borderRadius: 999, padding: '8px 10px',
    fontFamily: 'var(--font-sans)', fontSize: 13, fontWeight: 500,
    cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0,
  };
}

Object.assign(window, { CameraScreen, ReviewScreen });
