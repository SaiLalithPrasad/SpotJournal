# SpotJournal

A privacy-first photo journal for iOS. Every entry stays on your device — nothing is uploaded, tracked, or shared unless you choose to export it yourself.

## Features

- **Camera & Gallery** — Capture photos with the built-in camera or import from your photo library. EXIF metadata (date, location) is extracted automatically.
- **Location Tagging** — Entries are tagged with a readable place name via reverse geocoding.
- **Tags** — Create custom colored tags and filter entries by them.
- **Rich Captions** — Write plain text, bullet lists (`- item`), or numbered lists (`1. item`). URLs in captions are automatically detected and tappable.
- **Multiple Layouts** — Choose between Classic, Offset, and Split page layouts for viewing entries.
- **Theming** — Light and dark modes with a warm, paper-like aesthetic. Configurable caption typeface (Serif, Sans, Handwritten).
- **Export & Import** — Back up your entire journal (entries + photos) to a single `.spotjournal` file. Restore from a backup on any device.
- **Share Extension** — Share photos from other apps directly into SpotJournal.
- **Search & Browse** — Full-text search across captions and places, with date range filtering.

## Tech Stack

- **SwiftUI** — All UI
- **SwiftData** — Local persistence (`JournalEntry`, `Tag` models)
- **AVFoundation** — Camera capture
- **CoreLocation** — Location services and reverse geocoding
- **MapKit** — Coordinate handling

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Project Structure

```
SpotJournal/
├── SpotJournalApp.swift     # App entry point, seeding, share processing
├── AppState.swift           # Observable app state, SwiftData queries
├── Models.swift             # JournalEntry, Tag, PhotoKey models
├── ContentView.swift        # Main navigation, entry detail, edit sheet
├── HomeView.swift           # Home screen with latest entry
├── BrowseView.swift         # Browsable list with search and filters
├── JournalPageView.swift    # Entry page layouts (classic, offset, split)
├── ReviewView.swift         # New entry review/caption editor
├── CameraView.swift         # Camera UI overlay
├── CameraService.swift      # AVFoundation camera session management
├── CameraPreviewView.swift  # Live camera preview layer
├── Components.swift         # Shared UI components, caption rendering
├── SettingsView.swift       # Settings sheet with export/import
├── EntryExporter.swift      # Archive format, export/import logic
├── PhotoStore.swift         # On-disk photo file management
├── PhotoMetadata.swift      # EXIF extraction and geocoding
├── PlaceholderPhotos.swift  # Seed entry placeholder images
├── LocationService.swift    # CLLocationManager wrapper
├── SharedContainer.swift    # App group container for share extension
└── Theme.swift              # Color palette and theme definitions
```

## Privacy

SpotJournal stores all data locally on your device using SwiftData and the app's sandboxed file system. No analytics, no accounts, no cloud sync. The export feature creates a local file that you control entirely.

## License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.
