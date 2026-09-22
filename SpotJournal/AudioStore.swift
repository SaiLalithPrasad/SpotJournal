import Foundation
import AVFoundation

/// On-disk storage for voice-note audio files, mirroring `PhotoStore`.
/// Files live in Documents/Audio and are referenced by a stable filename (never
/// a full path) on `JournalEntry`, so they survive app-container path changes.
enum AudioStore {
    private static var audioDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Audio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Full URL for a stored audio filename, resolved against the current container.
    static func url(for filename: String) -> URL {
        audioDirectory.appendingPathComponent(filename)
    }

    /// UUID-based filename to guarantee uniqueness (no timestamp collisions).
    private static func generateFilename() -> String {
        "AUD_\(UUID().uuidString).m4a"
    }

    /// Move a temporary recording into permanent storage; returns the filename.
    static func save(from tempURL: URL) throws -> String {
        let filename = generateFilename()
        let dest = audioDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return filename
    }

    /// Save raw audio data (used by import); returns the filename.
    static func save(_ data: Data) throws -> String {
        let filename = generateFilename()
        let dest = audioDirectory.appendingPathComponent(filename)
        try data.write(to: dest, options: .atomic)
        return filename
    }

    /// Load raw audio data by filename (for export).
    static func loadData(_ filename: String) -> Data? {
        try? Data(contentsOf: audioDirectory.appendingPathComponent(filename))
    }

    /// Delete an audio file by filename.
    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: audioDirectory.appendingPathComponent(filename))
    }

    /// Duration in seconds of a stored file (fallback when not known from the recorder).
    static func duration(of filename: String) -> Double {
        (try? AVAudioPlayer(contentsOf: url(for: filename)))?.duration ?? 0
    }
}
