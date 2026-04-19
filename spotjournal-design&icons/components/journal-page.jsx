// SpotJournal — the entry "page" component (renders one entry full-screen).
// No more folio marks or book framing — just the pasted photo, caption,
// and typeset footer.
// Exports: JournalPage.

function JournalPage({ entry, layout = 'classic', captionFont = 'serif' }) {
  const font = captionFont === 'sans' ? 'ink-sans' : captionFont === 'hand' ? 'ink-hand' : 'ink-serif';

  if (layout === 'offset') {
    return (
      <div className="paper" style={{
        minHeight: '100%',
        padding: '96px 28px 40px',
        position: 'relative',
        display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ marginTop: 8, marginBottom: 28, marginLeft: -6 }}>
          <PhotoPaste photoKey={entry.photoKey} width={210} height={250} rotate={-3.2} />
        </div>
        <div className={font + ' ink-1'} style={{
          fontSize: captionFont === 'hand' ? 26 : 19,
          lineHeight: captionFont === 'hand' ? 1.25 : 1.5,
          textWrap: 'pretty',
        }}>{entry.caption}</div>
        <div style={{ flex: 1 }}/>
        <div style={{ marginTop: 32 }}>
          <PageTimestamp date={entry.date} place={entry.place} align="left"/>
        </div>
      </div>
    );
  }

  if (layout === 'split') {
    return (
      <div className="paper" style={{
        minHeight: '100%',
        padding: '96px 24px 40px',
        position: 'relative',
        display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ marginBottom: 24 }}>
          <PhotoPaste photoKey={entry.photoKey} width={296} height={300} rotate={0.5} tape={false}/>
        </div>
        <hr className="hairline" style={{ margin: '0 0 18px', width: '100%' }}/>
        <div className={font + ' ink-1'} style={{
          fontSize: captionFont === 'hand' ? 26 : 18,
          lineHeight: captionFont === 'hand' ? 1.25 : 1.55,
          textWrap: 'pretty',
        }}>{entry.caption}</div>
        <div style={{ flex: 1 }}/>
        <div style={{ marginTop: 28 }}>
          <PageTimestamp date={entry.date} place={entry.place} align="left"/>
        </div>
      </div>
    );
  }

  // ── Classic layout (default) ────────────────────────────────
  return (
    <div className="paper" style={{
      minHeight: '100%',
      padding: '96px 28px 40px',
      position: 'relative',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ marginBottom: 28 }}>
        <PhotoPaste photoKey={entry.photoKey} width={248} height={290} rotate={-1.4}/>
      </div>
      <div className={font + ' ink-1'} style={{
        fontSize: captionFont === 'hand' ? 28 : 19,
        lineHeight: captionFont === 'hand' ? 1.25 : 1.55,
        textWrap: 'pretty',
        textAlign: 'center',
        padding: '0 6px',
      }}>{entry.caption}</div>
      <div style={{ flex: 1 }}/>
      <div style={{ marginTop: 32 }}>
        <PageTimestamp date={entry.date} place={entry.place} align="center"/>
      </div>
    </div>
  );
}

Object.assign(window, { JournalPage });
