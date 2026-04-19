// SpotJournal — shared helpers and the journal "page" component.
// Exports via window: JournalPage, PhotoPaste, PageTimestamp, Icon,
//   PLACEHOLDER_PHOTOS, sampleEntries, LAYOUTS, formatStamp.

// ─── Lucide-style line icons (1.5px stroke) ──────────────────
function Icon({ name, size = 24, stroke, style = {} }) {
  const s = size;
  const common = {
    width: s, height: s, viewBox: '0 0 24 24', fill: 'none',
    stroke: stroke || 'currentColor', strokeWidth: 1.75,
    strokeLinecap: 'round', strokeLinejoin: 'round',
    style,
  };
  switch (name) {
    case 'camera': return (
      <svg {...common}>
        <path d="M14.5 4h-5L7.5 6.5h-3A1.5 1.5 0 0 0 3 8v10a1.5 1.5 0 0 0 1.5 1.5h15A1.5 1.5 0 0 0 21 18V8a1.5 1.5 0 0 0-1.5-1.5h-3L14.5 4z"/>
        <circle cx="12" cy="13" r="4"/>
      </svg>
    );
    case 'video': return (
      <svg {...common}>
        <rect x="2.5" y="6.5" width="13" height="11" rx="2"/>
        <path d="M15.5 10.5l5-2.5v8l-5-2.5"/>
      </svg>
    );
    case 'flip': return (
      <svg {...common}>
        <path d="M4 8a8 8 0 0 1 14-4"/>
        <path d="M18 3v5h-5"/>
        <path d="M20 16a8 8 0 0 1-14 4"/>
        <path d="M6 21v-5h5"/>
      </svg>
    );
    case 'close': return (
      <svg {...common}>
        <path d="M5 5l14 14M19 5L5 19"/>
      </svg>
    );
    case 'check': return (
      <svg {...common}>
        <path d="M4.5 12.5l5 5 10-11"/>
      </svg>
    );
    case 'retake': return (
      <svg {...common}>
        <path d="M3 12a9 9 0 1 0 3-6.7"/>
        <path d="M3 3v5h5"/>
      </svg>
    );
    case 'chevron-left': return (
      <svg {...common}>
        <path d="M15 5l-7 7 7 7"/>
      </svg>
    );
    case 'chevron-right': return (
      <svg {...common}>
        <path d="M9 5l7 7-7 7"/>
      </svg>
    );
    case 'map-pin': return (
      <svg {...common}>
        <path d="M12 21s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12z"/>
        <circle cx="12" cy="9" r="2.5"/>
      </svg>
    );
    case 'flash': return (
      <svg {...common}>
        <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/>
      </svg>
    );
    case 'flash-off': return (
      <svg {...common}>
        <path d="M13 2L4 14h4"/>
        <path d="M11 14h2l-1 8 9-12h-5"/>
        <path d="M3 3l18 18"/>
      </svg>
    );
    case 'settings': return (
      <svg {...common}>
        <circle cx="12" cy="12" r="2.5"/>
        <path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.8-.3 1.6 1.6 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-1-1.5 1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0 .3-1.8 1.6 1.6 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.5-1 1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3h.1a1.6 1.6 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 1 1.5 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8v.1a1.6 1.6 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/>
      </svg>
    );
    case 'book': return (
      <svg {...common}>
        <path d="M4 4.5A1.5 1.5 0 0 1 5.5 3H20v16.5H5.5A1.5 1.5 0 0 0 4 21"/>
        <path d="M4 4.5V21"/>
      </svg>
    );
    case 'calendar': return (
      <svg {...common}>
        <rect x="3.5" y="5" width="17" height="15.5" rx="2"/>
        <path d="M3.5 10h17"/>
        <path d="M8 3.5v3M16 3.5v3"/>
      </svg>
    );
    case 'grid': return (
      <svg {...common}>
        <rect x="3.5" y="3.5" width="7" height="7" rx="1"/>
        <rect x="13.5" y="3.5" width="7" height="7" rx="1"/>
        <rect x="3.5" y="13.5" width="7" height="7" rx="1"/>
        <rect x="13.5" y="13.5" width="7" height="7" rx="1"/>
      </svg>
    );
    case 'arrow-left': return (
      <svg {...common}>
        <path d="M10 5l-7 7 7 7"/>
        <path d="M3 12h18"/>
      </svg>
    );
    default: return null;
  }
}

// ─── Placeholder "photographs" — warm tonal gradient panels ──
// Each is a layered SVG that reads as a photo at phone scale.
const PLACEHOLDER_PHOTOS = {
  window: (
    <svg width="100%" height="100%" viewBox="0 0 300 360" preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      <defs>
        <linearGradient id="ph-win-sky" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="#F2C98E"/>
          <stop offset="60%" stopColor="#E29765"/>
          <stop offset="100%" stopColor="#A85A3D"/>
        </linearGradient>
        <linearGradient id="ph-win-sill" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="#4A362A"/>
          <stop offset="100%" stopColor="#2A1E18"/>
        </linearGradient>
      </defs>
      <rect width="300" height="360" fill="url(#ph-win-sky)"/>
      {/* sun */}
      <circle cx="210" cy="150" r="42" fill="#FFE6B0" opacity="0.9"/>
      <circle cx="210" cy="150" r="64" fill="#FFE6B0" opacity="0.25"/>
      {/* horizon rooftops */}
      <path d="M0 240 L40 220 L80 235 L120 215 L160 240 L200 225 L240 245 L300 220 L300 360 L0 360 Z" fill="#6B3E2A" opacity="0.8"/>
      <path d="M0 270 L60 260 L110 270 L180 255 L240 275 L300 260 L300 360 L0 360 Z" fill="#3E241B"/>
      {/* window frame cross */}
      <rect x="0" y="0" width="300" height="360" fill="none" stroke="#2A1E18" strokeWidth="14"/>
      <rect x="142" y="0" width="16" height="360" fill="url(#ph-win-sill)"/>
      <rect x="0" y="172" width="300" height="14" fill="url(#ph-win-sill)"/>
    </svg>
  ),
  coffee: (
    <svg width="100%" height="100%" viewBox="0 0 300 360" preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      <defs>
        <radialGradient id="ph-cof-bg" cx="0.5" cy="0.4" r="0.8">
          <stop offset="0%" stopColor="#E8D4B0"/>
          <stop offset="100%" stopColor="#8A6A48"/>
        </radialGradient>
      </defs>
      <rect width="300" height="360" fill="url(#ph-cof-bg)"/>
      {/* saucer */}
      <ellipse cx="150" cy="230" rx="130" ry="30" fill="#3B2A1E" opacity="0.9"/>
      <ellipse cx="150" cy="225" rx="120" ry="24" fill="#C8A574"/>
      {/* cup */}
      <path d="M80 220 Q80 120 150 120 Q220 120 220 220 Z" fill="#F1E3C9"/>
      <path d="M80 220 Q80 120 150 120 Q220 120 220 220" fill="none" stroke="#2A1E14" strokeWidth="3"/>
      {/* coffee */}
      <ellipse cx="150" cy="135" rx="65" ry="10" fill="#2A180E"/>
      <ellipse cx="150" cy="135" rx="60" ry="6" fill="#4B2E1A" opacity="0.6"/>
      {/* handle */}
      <path d="M220 160 Q260 160 260 195 Q260 225 220 225" fill="none" stroke="#F1E3C9" strokeWidth="14" strokeLinecap="round"/>
      {/* steam */}
      <path d="M130 90 Q120 70 135 50 Q150 35 140 15" fill="none" stroke="#FFF" strokeWidth="3" opacity="0.5" strokeLinecap="round"/>
      <path d="M165 90 Q175 70 160 50 Q148 35 160 15" fill="none" stroke="#FFF" strokeWidth="3" opacity="0.4" strokeLinecap="round"/>
    </svg>
  ),
  trail: (
    <svg width="100%" height="100%" viewBox="0 0 300 360" preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      <defs>
        <linearGradient id="ph-tr-sky" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="#D7C99E"/>
          <stop offset="100%" stopColor="#B89A66"/>
        </linearGradient>
      </defs>
      <rect width="300" height="360" fill="url(#ph-tr-sky)"/>
      {/* distant mtns */}
      <path d="M0 200 L50 160 L100 185 L160 140 L210 175 L260 150 L300 180 L300 260 L0 260 Z" fill="#5E4A36" opacity="0.7"/>
      <path d="M0 220 L40 195 L90 215 L150 180 L210 210 L270 195 L300 215 L300 280 L0 280 Z" fill="#3F3125" opacity="0.85"/>
      {/* ground */}
      <rect y="255" width="300" height="105" fill="#6D5438"/>
      {/* trail */}
      <path d="M150 360 Q160 300 140 260 Q120 230 150 200" fill="none" stroke="#D6B884" strokeWidth="24" strokeLinecap="round"/>
      {/* trees */}
      <g fill="#1E2A1C">
        <path d="M50 270 L40 300 L60 300 Z"/>
        <path d="M250 265 L238 305 L262 305 Z"/>
        <path d="M220 285 L212 320 L230 320 Z"/>
        <path d="M70 290 L62 330 L80 330 Z"/>
      </g>
    </svg>
  ),
  plate: (
    <svg width="100%" height="100%" viewBox="0 0 300 360" preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      <rect width="300" height="360" fill="#2B2620"/>
      {/* plate */}
      <circle cx="150" cy="190" r="140" fill="#EEE8D8"/>
      <circle cx="150" cy="190" r="128" fill="#F8F2E2"/>
      {/* pasta */}
      <circle cx="150" cy="190" r="90" fill="#D8A75A"/>
      <g stroke="#B8872F" strokeWidth="3" fill="none" opacity="0.7">
        <path d="M90 180 Q110 160 140 175 Q170 190 200 170 Q220 160 210 200"/>
        <path d="M100 210 Q130 200 150 215 Q180 230 210 210"/>
        <path d="M110 160 Q140 145 170 160 Q195 175 215 160"/>
      </g>
      {/* tomatoes */}
      <circle cx="130" cy="175" r="8" fill="#C73B35"/>
      <circle cx="170" cy="210" r="7" fill="#C73B35"/>
      <circle cx="190" cy="180" r="6" fill="#C73B35"/>
      {/* basil */}
      <ellipse cx="145" cy="195" rx="10" ry="4" fill="#3E6A2A" transform="rotate(20 145 195)"/>
      <ellipse cx="175" cy="190" rx="8" ry="3" fill="#3E6A2A" transform="rotate(-15 175 190)"/>
    </svg>
  ),
  viewfinder: (
    // Camera viewfinder preview — a warm-lit room
    <svg width="100%" height="100%" viewBox="0 0 400 700" preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      <defs>
        <linearGradient id="vf-bg" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="#D8A868"/>
          <stop offset="60%" stopColor="#9A5E3C"/>
          <stop offset="100%" stopColor="#3A2218"/>
        </linearGradient>
      </defs>
      <rect width="400" height="700" fill="url(#vf-bg)"/>
      {/* distant lamp */}
      <circle cx="280" cy="240" r="50" fill="#FFE0A8" opacity="0.9"/>
      <circle cx="280" cy="240" r="100" fill="#FFD78A" opacity="0.15"/>
      {/* table silhouette */}
      <rect x="0" y="520" width="400" height="180" fill="#1E130C"/>
      <path d="M0 520 L400 520 L400 540 L0 540 Z" fill="#4A2E1D"/>
      {/* book on table */}
      <rect x="120" y="480" width="140" height="42" fill="#6E3E26" rx="2"/>
      <rect x="124" y="484" width="132" height="36" fill="#874E32" rx="1"/>
      {/* coffee mug */}
      <rect x="70" y="485" width="45" height="38" rx="4" fill="#E9D8B8"/>
      <rect x="72" y="490" width="41" height="6" fill="#3A1E10"/>
    </svg>
  ),
};

// ─── Format timestamp + location for bottom-of-page line ──────
function formatStamp(date, place) {
  const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  const d = date;
  const time = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase();
  const day = `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
  return { day, time, place };
}

// ─── Sample entries ───────────────────────────────────────────
const sampleEntries = [
  {
    id: 'e-1',
    photoKey: 'window',
    caption: 'Light through the kitchen window again. There is a particular slant it takes in April that I have been trying to name for weeks.',
    date: new Date('2026-04-17T18:42:00'),
    place: 'Cobble Hill, Brooklyn',
  },
  {
    id: 'e-2',
    photoKey: 'coffee',
    caption: 'First cup from the new beans. Nutty, a little chocolate, not as bright as I was hoping. Trying a coarser grind tomorrow.',
    date: new Date('2026-04-18T07:14:00'),
    place: 'Home',
  },
  {
    id: 'e-3',
    photoKey: 'trail',
    caption: 'Walked the long way and the trail was empty. A good silence.',
    date: new Date('2026-04-15T08:03:00'),
    place: 'Prospect Park',
  },
  {
    id: 'e-4',
    photoKey: 'plate',
    caption: 'Made the pasta again. Still not right, but closer. The sauce wants more time.',
    date: new Date('2026-04-12T20:17:00'),
    place: 'Home',
  },
  {
    id: 'e-5',
    photoKey: 'window',
    caption: 'Rain all day. Read two chapters and slept an hour in the middle.',
    date: new Date('2026-04-09T15:22:00'),
    place: 'Home',
  },
  {
    id: 'e-6',
    photoKey: 'coffee',
    caption: 'Early meeting, early cup. I keep forgetting how much I like mornings.',
    date: new Date('2026-04-03T06:48:00'),
    place: 'Home',
  },
  {
    id: 'e-7',
    photoKey: 'trail',
    caption: 'First warm day. Everyone is out. A kid was naming every tree.',
    date: new Date('2026-03-28T11:30:00'),
    place: 'Prospect Park',
  },
];

// ─── Layout variants — where photo/caption/timestamp sit ──────
const LAYOUTS = {
  classic: {
    name: 'Classic',
    blurb: 'Photo at the top, caption below, date at the foot.',
  },
  offset: {
    name: 'Offset',
    blurb: 'Photo pushed to one side, caption wraps beside it.',
  },
  split: {
    name: 'Split',
    blurb: 'Photo fills the upper half, caption and date stack below a rule.',
  },
};

// ─── Photo taped to page ──────────────────────────────────────
function PhotoPaste({ photoKey, width = 232, height = 280, rotate = -1.6, tape = true, tapeColor, children }) {
  return (
    <div style={{
      position: 'relative',
      width, height,
      transform: `rotate(${rotate}deg)`,
      margin: '0 auto',
    }}>
      <div className="photo-paste" style={{
        width: '100%', height: '100%', overflow: 'hidden',
        borderRadius: 1,
      }}>
        {photoKey && PLACEHOLDER_PHOTOS[photoKey]}
        {children}
      </div>
      {tape && (
        <>
          <div className="tape" style={{ top: -10, left: '12%', transform: 'rotate(-8deg)', ...(tapeColor ? {background: tapeColor} : {}) }} />
          <div className="tape" style={{ top: -10, right: '12%', transform: 'rotate(6deg)', ...(tapeColor ? {background: tapeColor} : {}) }} />
        </>
      )}
    </div>
  );
}

// ─── Timestamp line — typeset small caps ──────────────────────
function PageTimestamp({ date, place, align = 'center' }) {
  const s = formatStamp(date, place);
  return (
    <div style={{ textAlign: align }}>
      <hr className="hairline" style={{ margin: '0 auto 12px', width: '40%' }}/>
      <div className="typeset ink-2" style={{ fontSize: 11, lineHeight: 1.5 }}>
        {s.day} <span className="ink-3" style={{ margin: '0 6px' }}>·</span> {s.time}
      </div>
      {place && (
        <div className="typeset ink-3" style={{ fontSize: 10.5, marginTop: 2 }}>
          {place}
        </div>
      )}
    </div>
  );
}

Object.assign(window, {
  Icon,
  PLACEHOLDER_PHOTOS,
  sampleEntries,
  LAYOUTS,
  formatStamp,
  PhotoPaste,
  PageTimestamp,
});
