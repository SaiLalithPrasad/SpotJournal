import SwiftUI
import UniformTypeIdentifiers

struct SettingsSheet: View {
    @Environment(AppState.self) private var state
    @State private var draftName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExportingPDF = false
    @State private var exportProgress: Double = 0
    @State private var showingImport = false
    @State private var importMessage: String?

    private let fonts: [(id: CaptionFont, label: String, sample: String)] = [
        (.serif, "Typeset", "The morning was quiet."),
        (.sans, "Plain", "The morning was quiet."),
        (.hand, "Written", "The morning was quiet."),
    ]

    var body: some View {
        let theme = state.theme

        ZStack {
            // Scrim
            theme.scrim
                .ignoresSafeArea()
                .onTapGesture { state.settingsOpen = false }

            // Sheet
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Grabber
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.border2)
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 4)

                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 24, design: .serif))
                            .foregroundColor(theme.fg1)

                        Spacer()

                        Button {
                            state.settingsOpen = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.fg1)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(theme.surfaceSunken))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("JOURNAL NAME", theme: theme)

                                TextField("Give your journal a name", text: $draftName)
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.fg1)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(theme.border2, lineWidth: 1)
                                            )
                                    )
                                    .onChange(of: draftName) { _, newValue in
                                        state.name = newValue
                                    }

                                Text("Stays on this device. Always.")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.fg3)
                            }

                            // Caption typeface
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("CAPTION TYPEFACE", theme: theme)

                                ForEach(fonts, id: \.id) { f in
                                    fontPickerRow(f: f, theme: theme)
                                }
                            }

                            // Appearance
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("APPEARANCE", theme: theme)

                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    state.isDark.toggle()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(state.isDark ? "Dark" : "Light")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(theme.fg1)
                                            Text("Tap to switch")
                                                .font(.system(size: 13))
                                                .foregroundColor(theme.fg3)
                                        }

                                        Spacer()

                                        // Toggle
                                        ZStack(alignment: state.isDark ? .trailing : .leading) {
                                            Capsule()
                                                .fill(state.isDark ? theme.accent : theme.border2)
                                                .frame(width: 44, height: 26)

                                            Circle()
                                                .fill(.white)
                                                .frame(width: 20, height: 20)
                                                .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                                                .padding(3)
                                        }
                                        .animation(.easeInOut(duration: 0.18), value: state.isDark)
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(theme.border1, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // OLED Dark Mode toggle (only visible when dark mode is on)
                                if state.isDark {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        state.useOLED.toggle()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("OLED Dark Mode")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(theme.fg1)
                                                Text(state.useOLED ? "True black • Battery saving" : "Enhanced dark mode")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(theme.fg3)
                                            }

                                            Spacer()

                                            // Toggle
                                            ZStack(alignment: state.useOLED ? .trailing : .leading) {
                                                Capsule()
                                                    .fill(state.useOLED ? theme.accent : theme.border2)
                                                    .frame(width: 44, height: 26)

                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 20, height: 20)
                                                    .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                                                    .padding(3)
                                            }
                                            .animation(.easeInOut(duration: 0.18), value: state.useOLED)
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(theme.border1, lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                if state.isDark && state.useOLED {
                                    Text("OLED mode uses true black (#000000) for maximum contrast and battery savings on OLED displays.")
                                        .font(.system(size: 13))
                                        .foregroundColor(theme.fg3)
                                        .transition(.opacity)
                                }
                            }

                            // Export & Import
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("YOUR JOURNAL", theme: theme)

                                Button {
                                    exportJournal()
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14))
                                        Text("Export")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.fg3)
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
                                .disabled(isExporting || isExportingPDF)

                                Button {
                                    exportPDF()
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.richtext")
                                            .font(.system(size: 14))
                                        Text("Export as PDF")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.fg3)
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
                                .disabled(isExportingPDF || isExporting)

                                Button {
                                    showingImport = true
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 14))
                                        Text("Import")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.fg3)
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

                                Text("Export saves entries to a .spotjournal backup. PDF creates a printable version. Import restores from a backup.")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.fg3)
                            }

                            // Delete all
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("DANGER ZONE", theme: theme)

                                Button {
                                    showDeleteConfirmation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                        Text("Delete All Entries")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .foregroundColor(theme.danger)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(theme.danger.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                Text("This cannot be undone.")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.fg3)
                            }

                            // About
                            VStack(spacing: 4) {
                                Text("SpotJournal \u{00B7} v1.0")
                                    .font(.system(size: 10, design: .serif))
                                    .fontWeight(.medium)
                                    .tracking(2)
                                    .textCase(.uppercase)
                                    .foregroundColor(theme.ink3)

                                Text("Nothing leaves this phone.")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.fg3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .background(theme.bg)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        topTrailingRadius: 28
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 20, y: -12)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.85
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            draftName = state.name
        }
        .alert("Delete All Entries?", isPresented: $showDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                state.deleteAllEntries()
                state.settingsOpen = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Since none of your data is uploaded anywhere, you will lose all journal entries and photos permanently. This cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ActivityView(url: url)
                    .presentationDetents([.medium, .large])
            }
        }
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Complete", isPresented: .init(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("OK") { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
        }
        .overlay {
            if isExporting || isExportingPDF {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text(isExportingPDF ? "Creating PDF..." : "Exporting...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.fg1)

                        ProgressView(value: exportProgress)
                            .tint(theme.accent)
                            .frame(width: 200)

                        Text("\(Int(exportProgress * 100))%")
                            .font(.system(size: 13))
                            .foregroundColor(theme.fg3)
                            .monospacedDigit()
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.surface)
                            .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
                    )
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isExporting || isExportingPDF)
            }
        }
    }

    private func exportJournal() {
        isExporting = true
        exportProgress = 0
        let entries = state.entries
        let progress = ProgressBox()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            exportProgress = progress.value
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<URL, Error>
            do {
                let url = try EntryExporter.exportToFile(entries) { p in
                    progress.value = p
                }
                result = .success(url)
            } catch {
                result = .failure(error)
            }
            DispatchQueue.main.async {
                timer.invalidate()
                switch result {
                case .success(let url):
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    exportURL = url
                    isExporting = false
                    showingShareSheet = true
                case .failure(let error):
                    isExporting = false
                    importMessage = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func exportPDF() {
        isExportingPDF = true
        exportProgress = 0
        let entries = state.entries
        let journalName = state.name
        let font = state.captionFont
        let progress = ProgressBox()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            exportProgress = progress.value
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let url = PDFExporter.exportPDFToFile(
                entries: entries,
                journalName: journalName,
                captionFont: font
            ) { p in
                progress.value = p
            }
            DispatchQueue.main.async {
                timer.invalidate()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                exportURL = url
                isExportingPDF = false
                showingShareSheet = true
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importMessage = "Could not access the file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let context = state.modelContext else {
                importMessage = "Could not read the file."
                return
            }

            do {
                let count = try EntryExporter.importFromFile(url, into: context)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                state.refreshTrigger += 1
                importMessage = count > 0
                    ? "Imported \(count) entr\(count == 1 ? "y" : "ies")."
                    : "No new entries to import (all already exist)."
            } catch {
                importMessage = "Import failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            importMessage = "Could not pick file: \(error.localizedDescription)"
        }
    }

    private func sectionHeader(_ text: String, theme: JournalTheme) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .tracking(1)
            .foregroundColor(theme.fg3)
    }

    private func fontPickerRow(f: (id: CaptionFont, label: String, sample: String), theme: JournalTheme) -> some View {
        let isSelected = state.captionFont == f.id

        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            state.captionFont = f.id
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(f.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.fg1)
                    Text(f.sample)
                        .font(captionFont(for: f.id, size: f.id == .hand ? 22 : 16))
                        .foregroundColor(theme.fg2)
                        .lineLimit(1)
                }

                Spacer()

                // Radio indicator
                Circle()
                    .stroke(isSelected ? theme.accent : theme.border2, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle().fill(theme.accent).frame(width: 20, height: 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accent : theme.border1, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Box

/// Thread-safe progress holder for bridging GCD background work to the main thread.
private final class ProgressBox: @unchecked Sendable {
    var value: Double = 0
}

// MARK: - Activity View (Share Sheet)

private struct ActivityView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
