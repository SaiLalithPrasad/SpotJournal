import SwiftUI
import AVFoundation

// MARK: - Voice Note State

/// Represents the voice note attached to an entry being created or edited.
enum VoiceNoteState: Equatable {
    case none
    /// An already-saved voice note (filename on disk).
    case existing(String)
    /// A freshly recorded note held in a temp file, with its duration.
    case recorded(URL, Double)

    /// URL to play back the current note, if any.
    var playbackURL: URL? {
        switch self {
        case .none: return nil
        case .existing(let name): return AudioStore.url(for: name)
        case .recorded(let url, _): return url
        }
    }

    var hasNote: Bool {
        if case .none = self { return false }
        return true
    }
}

// MARK: - Recorder Engine

@MainActor
@Observable
final class AudioRecorder {
    var isRecording = false
    var elapsed: TimeInterval = 0
    private(set) var recordingURL: URL?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    /// Cap recordings so file sizes stay bounded.
    static let maxDuration: TimeInterval = 600 // 10 minutes

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rec_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let r = try AVAudioRecorder(url: tempURL, settings: settings)
            r.record(forDuration: Self.maxDuration)
            recorder = r
            recordingURL = tempURL
            isRecording = true
            elapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let rec = self.recorder else { return }
                    self.elapsed = rec.currentTime
                    // Auto-stopped at maxDuration.
                    if !rec.isRecording { self.finishTimer() }
                }
            }
        } catch {
            isRecording = false
        }
    }

    /// Stop recording; returns the temp file URL and its duration.
    @discardableResult
    func stop() -> (URL, Double)? {
        let duration = recorder?.currentTime ?? elapsed
        recorder?.stop()
        finishTimer()
        guard let url = recordingURL else { return nil }
        return (url, duration)
    }

    /// Cancel and delete the in-progress recording.
    func discard() {
        recorder?.stop()
        finishTimer()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        elapsed = 0
    }

    private func finishTimer() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Playback Engine

@MainActor
@Observable
final class AudioPlayback: NSObject, AVAudioPlayerDelegate {
    var isPlaying = false
    var progress: Double = 0 // 0...1
    var duration: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var loadedURL: URL?

    func load(_ url: URL) {
        guard loadedURL != url else { return }
        stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        duration = player?.duration ?? 0
        loadedURL = url
        progress = 0
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard let player else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
        isPlaying = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let p = self.player else { return }
                self.progress = p.duration > 0 ? p.currentTime / p.duration : 0
            }
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        progress = 0
        timer?.invalidate()
        timer = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.progress = 0
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}

// MARK: - Time Formatting

func formatAudioTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let total = Int(seconds.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}

// MARK: - Playback Bar (read-only)

/// A compact play/pause + progress bar for a single voice note. Reused on the
/// journal page and inside the recorder section.
struct VoiceNotePlayerView: View {
    let url: URL
    var duration: Double = 0
    let theme: JournalTheme

    @State private var playback = AudioPlayback()

    var body: some View {
        HStack(spacing: 12) {
            Button {
                playback.toggle()
            } label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.fgOnAccent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(theme.accent))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(theme.accent)
                    Text("Voice note")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.fg2)
                    Spacer()
                    Text(formatAudioTime(displayTime))
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(theme.fg3)
                }

                // Progress track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.border2)
                            .frame(height: 4)
                        Capsule().fill(theme.accent)
                            .frame(width: max(0, geo.size.width * playback.progress), height: 4)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.border1, lineWidth: 1)
                )
        )
        .onAppear {
            playback.load(url)
            if duration > 0 { playback.duration = duration }
        }
        .onChange(of: url) { _, newURL in
            playback.load(newURL)
        }
        .onDisappear { playback.stop() }
    }

    private var displayTime: Double {
        let d = playback.duration > 0 ? playback.duration : duration
        return playback.isPlaying || playback.progress > 0 ? d * playback.progress : d
    }
}

// MARK: - Recorder Section (record / manage)

/// Full voice-note control for capture and edit screens: record when empty,
/// play + re-record + delete once a note exists. Communicates via `state`.
struct VoiceNoteSection: View {
    @Binding var state: VoiceNoteState
    /// Owned by the parent so a save can finalize an in-progress recording.
    var recorder: AudioRecorder
    let theme: JournalTheme

    @State private var permissionDenied = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VOICE NOTE")
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(theme.fg3)

            if recorder.isRecording {
                recordingBar
            } else if let url = state.playbackURL {
                VStack(spacing: 8) {
                    VoiceNotePlayerView(url: url, duration: currentDuration, theme: theme)
                    HStack(spacing: 10) {
                        Button {
                            beginRecording()
                        } label: {
                            controlLabel(icon: "arrow.counterclockwise", text: "Re-record")
                        }
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            controlLabel(icon: "trash", text: "Delete", tint: theme.danger)
                        }
                        Spacer()
                    }
                }
            } else {
                Button {
                    beginRecording()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                        Text("Record voice note")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(theme.fg1)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.border2, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            if permissionDenied {
                Text("Microphone access is off. Enable it in Settings to record.")
                    .font(.system(size: 12))
                    .foregroundColor(theme.fg3)
            }
        }
        .onDisappear {
            if recorder.isRecording { _ = recorder.stop() }
        }
        .alert("Delete Voice Note?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) { removeNote() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This voice note will be removed from the entry.")
        }
    }

    // MARK: Recording bar

    private var recordingBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(theme.danger)
                .frame(width: 10, height: 10)
                .opacity(0.9)

            Text(formatAudioTime(recorder.elapsed))
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(theme.fg1)

            Spacer()

            Button {
                stopRecording()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Stop")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(theme.fgOnAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(theme.accent))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.danger.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func controlLabel(icon: String, text: String, tint: Color? = nil) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(tint ?? theme.fg2)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(theme.surfaceSunken)
                .overlay(Capsule().stroke(theme.border1, lineWidth: 1))
        )
    }

    // MARK: Actions

    private var currentDuration: Double {
        switch state {
        case .recorded(_, let d): return d
        case .existing(let name): return AudioStore.duration(of: name)
        case .none: return 0
        }
    }

    private func beginRecording() {
        // Discard any prior fresh recording temp file before starting a new one.
        if case .recorded = state { discardTempIfNeeded() }
        Task {
            let granted = await recorder.requestPermission()
            if granted {
                permissionDenied = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                recorder.start()
            } else {
                permissionDenied = true
            }
        }
    }

    private func stopRecording() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let (url, duration) = recorder.stop() {
            state = .recorded(url, duration)
        }
    }

    private func removeNote() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        discardTempIfNeeded()
        state = .none
    }

    /// Delete the temp file backing a fresh (unsaved) recording.
    private func discardTempIfNeeded() {
        if case .recorded(let url, _) = state {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
