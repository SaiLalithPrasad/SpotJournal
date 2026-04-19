// SpotJournal — Browse screen with calendar + entry cards.
// Exports: BrowseScreen.

function sameDay(a, b) {
  return a.getFullYear() === b.getFullYear()
    && a.getMonth() === b.getMonth()
    && a.getDate() === b.getDate();
}

function MiniCalendar({ entries, selectedDate, onSelect, month, onMonth }) {
  // Build grid for `month` (a Date anchored to 1st)
  const year = month.getFullYear();
  const mo = month.getMonth();
  const firstDow = new Date(year, mo, 1).getDay(); // 0=Sun
  const daysIn = new Date(year, mo + 1, 0).getDate();

  const entrySet = new Set(entries.map(e => {
    const d = e.date;
    return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
  }));
  const hasEntry = (d, m, y) => entrySet.has(`${y}-${m}-${d}`);

  const today = new Date();

  const prev = () => onMonth(new Date(year, mo - 1, 1));
  const next = () => onMonth(new Date(year, mo + 1, 1));

  const monthLabel = month.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  const cells = [];
  for (let i = 0; i < firstDow; i++) cells.push(null);
  for (let d = 1; d <= daysIn; d++) cells.push(d);
  while (cells.length % 7 !== 0) cells.push(null);

  const dow = ['S','M','T','W','T','F','S'];

  return (
    <div style={{
      background: 'var(--surface)',
      border: '1px solid var(--border-1)',
      borderRadius: 16,
      padding: '14px 14px 10px',
      margin: '0 16px',
    }}>
      {/* header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 10,
      }}>
        <button onClick={prev} style={chevBtn}>
          <Icon name="chevron-left" size={16}/>
        </button>
        <div style={{
          fontFamily: 'var(--font-serif-display)', fontSize: 16,
          color: 'var(--fg-1)', letterSpacing: -0.2,
          fontWeight: 500,
        }}>{monthLabel}</div>
        <button onClick={next} style={chevBtn}>
          <Icon name="chevron-right" size={16}/>
        </button>
      </div>

      {/* day-of-week */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2,
        marginBottom: 4,
      }}>
        {dow.map((d, i) => (
          <div key={i} className="overline" style={{
            textAlign: 'center', fontSize: 9.5, color: 'var(--fg-3)',
            letterSpacing: 0.1,
          }}>{d}</div>
        ))}
      </div>

      {/* day cells */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2,
      }}>
        {cells.map((d, i) => {
          if (d === null) return <div key={i} style={{ height: 32 }}/>;
          const cellDate = new Date(year, mo, d);
          const has = hasEntry(d, mo, year);
          const isSelected = selectedDate && sameDay(cellDate, selectedDate);
          const isToday = sameDay(cellDate, today);
          return (
            <button
              key={i}
              onClick={() => onSelect(cellDate)}
              disabled={!has}
              style={{
                height: 32, borderRadius: 999, border: 0, padding: 0,
                background: isSelected ? 'var(--accent)' : 'transparent',
                color: isSelected ? 'var(--fg-on-accent)'
                       : has ? 'var(--fg-1)'
                       : 'var(--fg-4)',
                fontFamily: 'var(--font-sans)', fontSize: 13,
                fontWeight: isSelected || isToday ? 600 : 400,
                cursor: has ? 'pointer' : 'default',
                position: 'relative',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
              <span>{d}</span>
              {has && !isSelected && (
                <span style={{
                  position: 'absolute', bottom: 3,
                  width: 4, height: 4, borderRadius: 999,
                  background: 'var(--accent)',
                }}/>
              )}
              {isToday && !isSelected && (
                <span style={{
                  position: 'absolute', inset: 2, borderRadius: 999,
                  border: '1.5px solid var(--border-2)',
                  pointerEvents: 'none',
                }}/>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

const chevBtn = {
  width: 28, height: 28, borderRadius: 999, border: 0,
  background: 'var(--surface-sunken)', color: 'var(--fg-1)',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  cursor: 'pointer', padding: 0,
};

// ── Entry card — thumbnail + caption preview + date ────────
function EntryCard({ entry, onOpen }) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const d = entry.date;
  const dateLabel = `${months[d.getMonth()]} ${d.getDate()}`;
  const timeLabel = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase();

  return (
    <button onClick={onOpen} style={{
      display: 'flex', gap: 12,
      padding: 10,
      background: 'var(--surface)',
      border: '1px solid var(--border-1)',
      borderRadius: 14,
      width: '100%', textAlign: 'left',
      cursor: 'pointer',
      fontFamily: 'inherit',
      transition: 'background 120ms',
    }}>
      {/* thumb — the PhotoPaste treatment in miniature */}
      <div style={{
        width: 76, height: 92, flexShrink: 0,
        position: 'relative',
        background: '#d9c9a8',
        borderRadius: 2,
        overflow: 'hidden',
        boxShadow: '0 1px 2px rgba(70,45,20,0.10), 0 4px 10px rgba(70,45,20,0.08)',
      }}>
        {PLACEHOLDER_PHOTOS[entry.photoKey]}
      </div>

      <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 4, paddingTop: 2 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8,
        }}>
          <div className="typeset" style={{
            fontSize: 11, color: 'var(--fg-2)',
          }}>{dateLabel} · {timeLabel}</div>
        </div>
        <div style={{
          fontFamily: 'var(--font-serif-display)',
          fontSize: 15, lineHeight: 1.4,
          color: 'var(--fg-1)',
          letterSpacing: -0.1,
          display: '-webkit-box',
          WebkitLineClamp: 3,
          WebkitBoxOrient: 'vertical',
          overflow: 'hidden',
        }}>
          {entry.caption}
        </div>
        {entry.place && (
          <div style={{
            display: 'flex', alignItems: 'center', gap: 4,
            fontSize: 11, color: 'var(--fg-3)',
            fontFamily: 'var(--font-sans)',
            marginTop: 2,
          }}>
            <Icon name="map-pin" size={11}/>
            <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{entry.place}</span>
          </div>
        )}
      </div>
    </button>
  );
}

// ── Browse screen ──────────────────────────────────────────
function BrowseScreen({ entries, onBack, onOpen, onSettings }) {
  const [calendarOpen, setCalendarOpen] = React.useState(false);
  const [month, setMonth] = React.useState(() => {
    const d = entries[0]?.date || new Date();
    return new Date(d.getFullYear(), d.getMonth(), 1);
  });
  const [selectedDate, setSelectedDate] = React.useState(null);
  const scrollRef = React.useRef(null);
  const cardRefs = React.useRef({});

  // sort: most recent first
  const sorted = React.useMemo(() =>
    [...entries].sort((a, b) => b.date - a.date),
  [entries]);

  // group by month header
  const groups = React.useMemo(() => {
    const gs = [];
    let curr = null;
    const label = (d) => d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    for (const e of sorted) {
      const l = label(e.date);
      if (!curr || curr.label !== l) {
        curr = { label: l, items: [] };
        gs.push(curr);
      }
      curr.items.push(e);
    }
    return gs;
  }, [sorted]);

  const jumpToDate = (d) => {
    setSelectedDate(d);
    // find the first entry matching that day
    const match = sorted.find(e => sameDay(e.date, d));
    if (match) {
      const el = cardRefs.current[match.id];
      if (el && scrollRef.current) {
        const offset = el.offsetTop - 12;
        scrollRef.current.scrollTo({ top: offset, behavior: 'smooth' });
      }
    }
    setCalendarOpen(false);
  };

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'var(--bg)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* App header */}
      <div style={{
        paddingTop: 58, paddingLeft: 16, paddingRight: 16, paddingBottom: 10,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        background: 'var(--bg)',
        borderBottom: '1px solid var(--border-1)',
        zIndex: 5,
      }}>
        <button onClick={onBack} style={{
          width: 36, height: 36, borderRadius: 999, border: 0,
          background: 'var(--surface-sunken)', color: 'var(--fg-1)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', padding: 0,
        }}>
          <Icon name="chevron-left" size={18}/>
        </button>

        <div style={{
          fontFamily: 'var(--font-serif-display)', fontSize: 20,
          color: 'var(--fg-1)', letterSpacing: -0.3, fontWeight: 500,
        }}>Entries</div>

        <div style={{ display: 'flex', gap: 6 }}>
          <button onClick={() => setCalendarOpen(v => !v)} style={{
            width: 36, height: 36, borderRadius: 999, border: 0,
            background: calendarOpen ? 'var(--accent-soft)' : 'var(--surface-sunken)',
            color: calendarOpen ? 'var(--accent)' : 'var(--fg-1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', padding: 0,
          }}>
            <Icon name="calendar" size={17}/>
          </button>
          <button onClick={onSettings} style={{
            width: 36, height: 36, borderRadius: 999, border: 0,
            background: 'var(--surface-sunken)', color: 'var(--fg-1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', padding: 0,
          }}>
            <Icon name="settings" size={17}/>
          </button>
        </div>
      </div>

      {/* Collapsible calendar */}
      {calendarOpen && (
        <div style={{
          padding: '12px 0',
          borderBottom: '1px solid var(--border-1)',
          background: 'var(--bg-alt)',
          animation: 'fadeIn 160ms var(--ease-standard)',
        }}>
          <MiniCalendar
            entries={entries}
            selectedDate={selectedDate}
            onSelect={jumpToDate}
            month={month}
            onMonth={setMonth}
          />
          <div style={{ padding: '8px 16px 0', textAlign: 'center' }}>
            <div className="caption" style={{ fontSize: 11 }}>
              Dots show days you wrote.
            </div>
          </div>
        </div>
      )}

      {/* List of entries */}
      <div ref={scrollRef} style={{
        flex: 1, overflow: 'auto',
        padding: '16px 16px 40px',
      }}>
        {groups.map(g => (
          <div key={g.label} style={{ marginBottom: 20 }}>
            <div className="overline" style={{
              fontSize: 10, marginBottom: 10, paddingLeft: 4,
              color: 'var(--fg-3)',
            }}>{g.label}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {g.items.map(e => (
                <div key={e.id} ref={el => cardRefs.current[e.id] = el}>
                  <EntryCard entry={e} onOpen={() => onOpen(e)}/>
                </div>
              ))}
            </div>
          </div>
        ))}
        {entries.length === 0 && (
          <div style={{
            padding: '80px 20px', textAlign: 'center', color: 'var(--fg-3)',
            fontFamily: 'var(--font-sans)', fontSize: 14,
          }}>
            Nothing yet. Shoot your first.
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { BrowseScreen });
