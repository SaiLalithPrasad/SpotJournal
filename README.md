# SpotJournal

A privacy-first photo journal for iOS. Every entry stays on your device — nothing is uploaded, tracked, or shared unless you choose to export it yourself.

## Features

- **Camera & Gallery** — Capture photos with the built-in camera (with flash, zoom presets, pinch-to-zoom, tap-to-focus, front/back toggle) or import from your photo library. EXIF metadata (date, GPS) is extracted automatically. Zoom transitions use smooth animated ramps for a native camera feel.
- **Location Tagging** — Entries are tagged with a descriptive place name via reverse geocoding using MapKit (`MKReverseGeocodingRequest`). Displays POI name with city, state, and country context.
- **Tags** — Create custom colored tags (8 preset colors), assign them to entries, filter by them, and swipe-to-delete tags you no longer need. Deleting a tag cleanly removes it from all associated entries.
- **Rich Captions** — Write plain text, bullet lists (`- item`), or numbered lists (`1. item`). URLs in captions are automatically detected and tappable. Long captions are scrollable.
- **Multiple Layouts** — Choose between Classic, Offset, and Split page layouts for viewing entries.
- **Theming** — Light and dark modes with a warm, paper-like aesthetic. Three caption typefaces: Serif (Georgia), Sans (System), Handwritten (Bradley Hand).
- **Export (.spotjournal)** — Back up your entire journal (entries + photos + tags) to a single `.spotjournal` binary plist archive. Restore from a backup on any device with deduplication by timestamp.
- **Export (PDF)** — Generate a printable US Letter PDF with a cover page, one entry per page, photos scaled to fit, formatted captions (prose/bullets/numbered lists), metadata footers, and tag chips. Long captions overflow across pages using CoreText `CTFramesetter`.
- **Progress Tracking** — Both export types show a real-time progress popup with percentage using a GCD + Timer polling pattern.
- **Share Extension** — Share photos from other apps directly into SpotJournal via an App Group shared container. EXIF date and GPS are preserved.
- **Search & Browse** — Full-text search across captions and places, with date range filtering, live entry count, and swipe-to-delete entries.
- **Pinch-to-Zoom** — Full-screen zoomable photo viewer with double-tap to zoom, drag to pan, and swipe down to dismiss.
- **Markdown-lite Captions** — Captions support inline bullet and numbered list syntax, rendered with proper indentation in both the app UI and PDF export.
- **Haptic Feedback** — Tactile responses on shutter press, entry save, and entry deletion.
- **Tags on Pages** — Tag chips are displayed on journal entry pages alongside the timestamp.

## Tech Stack

| Framework | Usage |
|---|---|
| **SwiftUI** | All UI — views, navigation, theming, gestures |
| **SwiftData** | Local persistence for `JournalEntry` and `Tag` models |
| **AVFoundation** | Camera capture session, photo output, zoom control |
| **CoreLocation** | Location permission and continuous location updates |
| **MapKit** | Reverse geocoding via `MKReverseGeocodingRequest` and `MKAddressRepresentations` |
| **UIKit** | `UIGraphicsPDFRenderer` for PDF generation, `UIImage` for photo handling |
| **CoreText** | `CTFramesetter` for paginating long captions across PDF pages |
| **ImageIO** | EXIF metadata extraction (`CGImageSourceCopyPropertiesAtIndex`) |
| **UniformTypeIdentifiers** | File type handling for import/export |

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Architecture

The app uses a single `@Observable` class (`AppState`) as the central state manager, injected into the SwiftUI environment. Navigation is driven by an `AppScreen` enum. SwiftData provides the persistence layer with `ModelContainer` initialized at app launch.

```
SpotJournalApp (entry point)
    ├── AppState (@Observable)       ← holds navigation, settings, SwiftData context
    │   ├── entries: [JournalEntry]  ← fetched from SwiftData, sorted by date desc
    │   ├── allTags: [Tag]           ← fetched from SwiftData, sorted by name
    │   └── theme: JournalTheme     ← computed from isDark setting
    │
    ├── ContentView                  ← routes AppScreen to child views
    │   ├── HomeView                 ← latest entry display
    │   ├── BrowseView               ← searchable entry list
    │   ├── CameraView → ReviewView  ← capture → caption → save flow
    │   ├── JournalPageView          ← entry detail with layout variants
    │   └── SettingsSheet            ← settings, export, import, danger zone
    │
    └── Services
        ├── CameraService            ← AVCaptureSession management
        ├── LocationService          ← CLLocationManager wrapper
        ├── PhotoStore               ← file I/O for photos
        ├── PhotoMetadata            ← EXIF extraction + reverse geocoding
        ├── EntryExporter            ← .spotjournal archive codec
        ├── PDFExporter              ← PDF generation
        └── SharedContainer          ← App Group bridge for share extension
```

## Data Storage

### SwiftData Schema

The app persists data using SwiftData with two `@Model` classes in a single `ModelContainer`:

```swift
ModelContainer(for: JournalEntry.self, Tag.self)
```

The underlying SQLite database is stored at:
```
<App Sandbox>/Library/Application Support/default.store
```

#### JournalEntry

| Column | Type | Notes |
|---|---|---|
| `id` | `String` (unique) | Format: `e-<unix_timestamp>-<random_4_digits>` |
| `photoKeyRaw` | `String?` | Placeholder photo key (`window`, `coffee`, `trail`, `plate`) — `nil` for real photos |
| `photoFileName` | `String?` | Filename in the Photos directory — `nil` for placeholders |
| `caption` | `String` | Entry text, supports markdown-lite bullet/numbered list syntax |
| `date` | `Date` | Photo date (from EXIF or capture time) |
| `place` | `String` | Reverse-geocoded location string |
| `importedAt` | `Date?` | When the photo was imported (gallery/share); `nil` for live captures |
| `tags` | `[Tag]` | Many-to-many relationship |

#### Tag

| Column | Type | Notes |
|---|---|---|
| `id` | `String` (unique) | UUID string |
| `name` | `String` | User-defined tag name |
| `colorHex` | `UInt` | RGB hex value (e.g., `0xD97757`) |
| `entries` | `[JournalEntry]` | Inverse relationship, auto-managed by SwiftData |

The many-to-many relationship between `JournalEntry` and `Tag` is defined via:
```swift
// On Tag:
@Relationship(inverse: \JournalEntry.tags)
var entries: [JournalEntry] = []

// On JournalEntry:
var tags: [Tag] = []
```

SwiftData creates an intermediate join table in SQLite to manage this relationship.

### Photo Storage

Photos are stored as **JPEG files on the filesystem**, not in the database. This keeps the SQLite database small and allows efficient memory-mapped image loading.

```
<App Sandbox>/Documents/Photos/
├── IMG_1713474821_4827.jpg
├── IMG_1713561234_1092.jpg
└── ...
```

**Filename format:** `IMG_<unix_timestamp>_<random_0-9999>.jpg`

The `PhotoStore` enum manages all file operations:

| Operation | Method | Description |
|---|---|---|
| Save | `save(_ imageData: Data) -> String` | Writes JPEG data atomically, returns filename |
| Load image | `load(_ filename: String) -> UIImage?` | Loads UIImage from filename |
| Load data | `loadData(_ filename: String) -> Data?` | Loads raw bytes (used for export) |
| Delete | `delete(_ filename: String)` | Removes file from disk |

The `JournalEntry.photoFileName` field stores only the filename (not the full path). The full path is resolved at runtime by `PhotoStore`.

### User Preferences

Settings are stored in `UserDefaults` (not SwiftData):

| Key | Type | Default | Description |
|---|---|---|---|
| `isDark` | `Bool` | `false` | Dark mode toggle |
| `captionFont` | `String` | `"serif"` | Caption typeface (`serif`, `sans`, `hand`) |
| `layout` | `String` | `"classic"` | Page layout (`classic`, `offset`, `split`) |
| `name` | `String` | `""` | Journal name shown in settings and PDF cover |

### Share Extension

The share extension writes incoming photos to an App Group shared container:

```
<App Group: group.spotjournal.shared>/pending/
├── <uuid>.json        ← metadata (date, lat, lon, caption, image filename)
└── <uuid>.jpg         ← image data
```

On app launch (or return to foreground), `processPendingShares()` consumes these files, saves photos via `PhotoStore`, creates `JournalEntry` records, and reverse-geocodes any GPS coordinates.

## Export Formats

### .spotjournal Archive

A **binary property list** (`PropertyListEncoder` with `.binary` format) containing:

```swift
struct JournalArchive: Codable {
    let version: Int          // Currently 1
    let exportedAt: Date
    let entries: [ArchiveEntry]
}

struct ArchiveEntry: Codable {
    let caption: String
    let date: Date
    let place: String
    let importedAt: Date?
    let photoData: Data?       // Full JPEG bytes (nil for placeholders)
    let placeholderKey: String? // "window", "coffee", etc.
    let tags: [ArchiveTag]
}

struct ArchiveTag: Codable {
    let name: String
    let colorHex: UInt
}
```

Import deduplicates by matching `date.timeIntervalSince1970`. Existing tags are reused by name; new tags are created as needed.

### PDF Export

Generated using `UIGraphicsPDFRenderer` with US Letter dimensions (612 x 792 pt):

- **Cover page** — Journal name (or "My Journal"), date range, entry count, centered layout
- **Entry pages** — Photo scaled to max 40% page height, caption rendered as `NSAttributedString`, metadata footer with date/place/tags
- **Overflow** — Long captions paginate across multiple pages using `CTFramesetterCreateFrame` to determine visible text ranges
- **Tag chips** — Rendered as rounded rectangles with text overlay
- **Page numbers** — Centered at the bottom of each page (starting from page 2)

## Project Structure

```
SpotJournal/
├── SpotJournalApp.swift     # App entry point, ModelContainer, seeding, share processing
├── AppState.swift           # @Observable state: navigation, settings, CRUD, tag management
├── Models.swift             # @Model classes: JournalEntry, Tag; enums: PhotoKey, PhotoSource
├── ContentView.swift        # Root navigation, entry detail, edit sheet
├── HomeView.swift           # Home screen with latest entry
├── BrowseView.swift         # Searchable entry list with date filtering
├── JournalPageView.swift    # Entry page layouts (classic, offset, split)
├── ReviewView.swift         # New entry review, caption editor, tag picker sheet
├── CameraView.swift         # Camera UI overlay with flash/zoom/flip controls
├── CameraService.swift      # AVFoundation camera session, zoom presets, ramp zoom, tap-to-focus
├── CameraPreviewView.swift  # UIViewRepresentable with pinch/tap gesture recognizers
├── Components.swift         # Shared UI: photo views, caption rendering, zoom viewer, helpers
├── SettingsView.swift       # Settings sheet with export/import and progress overlay
├── EntryExporter.swift      # Archive export/import codec and PDF generation
├── PhotoStore.swift         # On-disk JPEG file management (Documents/Photos/)
├── PhotoMetadata.swift      # EXIF extraction (ImageIO) and reverse geocoding (MapKit)
├── PlaceholderPhotos.swift  # Seed entry placeholder images (SwiftUI-rendered)
├── LocationService.swift    # CLLocationManager wrapper with reverse geocoding
├── SharedContainer.swift    # App Group container bridge for share extension
└── Theme.swift              # JournalTheme struct, Color hex extension

SpotJournalShare/
├── ShareViewController.swift  # Share extension: receives photos, writes to App Group
└── Info.plist                 # Extension configuration

SpotJournalTests/
├── ModelsTests.swift          # 23 tests: ID generation, enums, entries, tags, deleteTag
├── CaptionParsingTests.swift  # 11 tests: parseCaptionBlocks, font/spacing helpers
├── EntryExporterTests.swift   # 14 tests: archive round-trip, PDF generation, progress
├── PhotoStoreTests.swift      # 7 tests: save/load/delete round-trips
└── ThemeTests.swift           # 8 tests: Color hex init, theme properties
```

## Tests

63 unit tests using the Swift Testing framework (`import Testing`). Tests cover:

- **Models** — ID generation format/uniqueness, enum raw values and labels, entry initialization for both placeholder and file-based entries, `PhotoSource` routing, tag creation and deletion with SwiftData in-memory containers
- **Caption Parsing** — Empty input, prose joining, bullet detection, numbered list detection, mixed content, edge cases (missing spaces), font size helpers
- **Entry Exporter** — Archive encode/decode round-trip, field and tag preservation, export date, file creation, filename format, progress callbacks, PDF generation (header validation, empty entries, bullet captions)
- **Photo Store** — Save/load round-trip, raw data loading, file deletion, nonexistent file handling, filename uniqueness
- **Theme** — Color hex parsing (black, white, red), light/dark mode flags, property accessibility

Run tests:
```bash
xcodebuild test -scheme SpotJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SpotJournalTests
```

## Privacy

SpotJournal stores all data locally on your device using SwiftData (SQLite) and the app's sandboxed file system. No analytics, no accounts, no cloud sync, no network requests except Apple's reverse geocoding API. The export feature creates a local file that you control entirely.

## License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.
