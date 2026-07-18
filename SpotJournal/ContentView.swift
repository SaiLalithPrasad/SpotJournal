import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ZStack {
            state.theme.bg.ignoresSafeArea()

            switch state.screen {
            case .home, .saved:
                if let entry = state.latest {
                    HomeView(entry: entry)
                        .transition(.opacity)
                } else {
                    emptyState
                }

            case .camera:
                CameraView()
                    .transition(.move(edge: .bottom))

            case .review:
                ReviewView()
                    .transition(.move(edge: .trailing))

            case .browse:
                BrowseView()
                    .transition(pushPopTransition)

            case .entry(let id):
                EntryDetailView(initialEntryId: id)
                    .transition(pushPopTransition)
            }

            // Settings overlay
            if state.settingsOpen {
                SettingsSheet()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.24), value: state.screen)
        .animation(.easeInOut(duration: 0.18), value: state.settingsOpen)
    }

    /// Slides forward (push) from the trailing edge, and back (pop) from the leading edge.
    private var pushPopTransition: AnyTransition {
        switch state.navDirection {
        case .forward:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .backward:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }

    private var emptyState: some View {
        let theme = state.theme
        return ZStack(alignment: .top) {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.fg4)

                Text("Take your first photo")
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(theme.fg3)

                Button {
                    state.screen = .camera
                } label: {
                    Text("Open Camera")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.fgOnAccent)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(theme.accent))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                IconChipButton(systemName: "gearshape", theme: theme) {
                    state.settingsOpen = true
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 14)
        }
    }
}

// MARK: - Entry Detail View

struct EntryDetailView: View {
    @Environment(AppState.self) private var state
    let initialEntryId: String

    @State private var currentId: String = ""
    @State private var editingEntry: JournalEntry?

    var body: some View {
        let theme = state.theme
        let sortedEntries = state.entries.sorted { $0.date > $1.date }

        ZStack(alignment: .top) {
            TabView(selection: $currentId) {
                ForEach(sortedEntries) { entry in
                    JournalPageView(
                        entry: entry,
                        layout: state.layout,
                        captionFontStyle: state.captionFont,
                        theme: theme
                    )
                    .tag(entry.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            HStack {
                IconChipButton(systemName: "chevron.left", theme: theme) {
                    state.screen = .browse
                }

                Spacer()

                IconChipButton(systemName: "pencil", theme: theme) {
                    editingEntry = sortedEntries.first { $0.id == currentId }
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 14)
        }
        .onAppear {
            currentId = initialEntryId
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry)
                .environment(state)
        }
    }
}

// MARK: - Edit Entry Sheet

struct EditEntrySheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry
    @State private var caption: String = ""
    @State private var listMode = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTagSheet = false
    @State private var selectedMoods: [Mood] = []
    @State private var showingMoodSheet = false
    @State private var photos: [EditPhoto] = []
    @State private var editPickerItems: [PhotosPickerItem] = []

    var body: some View {
        let theme = state.theme

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photos (hero + editable strip)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("PHOTOS")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(1)
                                .foregroundColor(theme.fg3)
                            Spacer()
                            Text("\(photos.count)/\(JournalEntry.maxPhotos)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(theme.fg4)
                        }

                        if let hero = photos.first {
                            editHero(hero)
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        editPhotoStrip(theme: theme)
                    }

                    // Caption
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("CAPTION")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(1)
                                .foregroundColor(theme.fg3)

                            Spacer()

                            Button {
                                listMode.toggle()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("List")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(listMode ? theme.accent : theme.fg3)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(listMode ? theme.accentSoft : theme.surfaceSunken)
                                        .overlay(
                                            Capsule().stroke(listMode ? theme.accent.opacity(0.3) : theme.border1, lineWidth: 1)
                                        )
                                )
                            }
                        }

                        TextField(
                            listMode ? "Add items, one per line\u{2026}" : "Write a caption\u{2026}",
                            text: $caption,
                            axis: .vertical
                        )
                        .lineLimit(3...8)
                        .font(captionFont(for: state.captionFont, size: 16))
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
                        .onChange(of: caption) { oldValue, newValue in
                            guard listMode else { return }
                            if newValue.hasSuffix("\n") && !oldValue.hasSuffix("\n") {
                                caption = newValue + "- "
                            }
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TAGS")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1)
                            .foregroundColor(theme.fg3)

                        FlowLayout(spacing: 8) {
                            ForEach(selectedTags) { tag in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 8, height: 8)
                                    Text(tag.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.fg1)
                                    Button {
                                        selectedTags.removeAll { $0.id == tag.id }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(theme.fg3)
                                            .frame(width: 22, height: 22)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .padding(.leading, 10)
                                .padding(.trailing, 4)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(tag.color.opacity(0.15))
                                        .overlay(Capsule().stroke(tag.color.opacity(0.3), lineWidth: 1))
                                )
                            }

                            Button {
                                showingTagSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("Tag")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(theme.fg2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(theme.surfaceSunken)
                                        .overlay(Capsule().stroke(theme.border1, lineWidth: 1))
                                )
                            }
                        }
                    }

                    // Moods
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MOODS")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1)
                            .foregroundColor(theme.fg3)

                        FlowLayout(spacing: 8) {
                            ForEach(selectedMoods) { mood in
                                HStack(spacing: 4) {
                                    Text(mood.emoji)
                                        .font(.system(size: 14))
                                    Text(mood.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.fg1)
                                    Button {
                                        selectedMoods.removeAll { $0.id == mood.id }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(theme.fg3)
                                            .frame(width: 22, height: 22)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .padding(.leading, 10)
                                .padding(.trailing, 4)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(mood.color.opacity(0.15))
                                        .overlay(Capsule().stroke(mood.color.opacity(0.3), lineWidth: 1))
                                )
                            }

                            Button {
                                showingMoodSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Mood")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(theme.fg2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(theme.surfaceSunken)
                                        .overlay(Capsule().stroke(theme.border1, lineWidth: 1))
                                )
                            }
                        }
                    }

                    // Date & location (read-only display)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DATE & LOCATION")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1)
                            .foregroundColor(theme.fg3)

                        Text(formattedDate)
                            .font(.system(size: 14))
                            .foregroundColor(theme.fg2)

                        if !entry.place.isEmpty {
                            Text(entry.place)
                                .font(.system(size: 14))
                                .foregroundColor(theme.fg3)
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.bg)
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingTagSheet) {
                TagPickerSheet(selectedTags: $selectedTags)
                    .environment(state)
            }
            .sheet(isPresented: $showingMoodSheet) {
                MoodPickerSheet(selectedMoods: $selectedMoods)
                    .environment(state)
            }
        }
        .onAppear {
            caption = entry.caption == "\u{2014}" ? "" : entry.caption
            selectedTags = entry.tags
            selectedMoods = entry.moods
            listMode = caption.contains("\n- ")
            if photos.isEmpty {
                photos = entry.resolvedFileNames.map { .existing($0) }
            }
        }
        .onChange(of: editPickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await addPickedPhotos(newItems)
                editPickerItems = []
            }
        }
    }

    // MARK: - Photos editing

    @ViewBuilder
    private func editHero(_ photo: EditPhoto) -> some View {
        switch photo {
        case .existing(let name):
            if let ui = PhotoStore.load(name) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        case .new(let data):
            if let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }

    @ViewBuilder
    private func editPhotoStrip(theme: JournalTheme) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    ZStack(alignment: .topTrailing) {
                        editThumb(photo)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(index == 0 ? theme.accent : theme.border1,
                                            lineWidth: index == 0 ? 2 : 1)
                            )

                        if photos.count > 1 {
                            Button {
                                removePhoto(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white, .black.opacity(0.55))
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                    .contextMenu {
                        if index > 0 {
                            Button { movePhoto(from: index, to: index - 1) } label: {
                                Label("Move Left", systemImage: "arrow.left")
                            }
                        }
                        if index < photos.count - 1 {
                            Button { movePhoto(from: index, to: index + 1) } label: {
                                Label("Move Right", systemImage: "arrow.right")
                            }
                        }
                        if photos.count > 1 {
                            Button(role: .destructive) {
                                removePhoto(at: index)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }

                if photos.count < JournalEntry.maxPhotos {
                    PhotosPicker(
                        selection: $editPickerItems,
                        maxSelectionCount: max(1, JournalEntry.maxPhotos - photos.count),
                        matching: .images
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.fg2)
                            .frame(width: 64, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.surfaceSunken)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(theme.border1, style: StrokeStyle(lineWidth: 1, dash: [3]))
                                    )
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func editThumb(_ photo: EditPhoto) -> some View {
        switch photo {
        case .existing(let name):
            if let ui = PhotoStore.loadThumbnail(name) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        case .new(let data):
            if let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }

    private func removePhoto(at index: Int) {
        guard photos.count > 1, index < photos.count else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        photos.remove(at: index)
    }

    private func movePhoto(from: Int, to: Int) {
        guard from < photos.count, to >= 0, to < photos.count else { return }
        let item = photos.remove(at: from)
        photos.insert(item, at: to)
    }

    private func addPickedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard photos.count < JournalEntry.maxPhotos else { break }
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(.new(data))
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy  \u{00B7}  h:mm a"
        return formatter.string(from: entry.date)
    }

    private func saveChanges() {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.caption = trimmed.isEmpty ? "\u{2014}" : trimmed
        entry.tags = selectedTags
        entry.moods = selectedMoods

        // Persist photo edits: keep existing filenames, save any new photos,
        // and delete files that were removed from the entry.
        let originalNames = Set(entry.resolvedFileNames)
        var finalNames: [String] = []
        for photo in photos {
            switch photo {
            case .existing(let name):
                finalNames.append(name)
            case .new(let data):
                if let name = try? PhotoStore.save(data) {
                    finalNames.append(name)
                }
            }
        }

        // Guard against an empty result (shouldn't happen — remove is blocked at 1).
        if finalNames.isEmpty, let fallback = entry.resolvedFileNames.first {
            finalNames = [fallback]
        }

        let keptNames = Set(finalNames)
        for removed in originalNames.subtracting(keptNames) {
            PhotoStore.delete(removed)
        }

        entry.photoFileNames = finalNames
        entry.photoFileName = finalNames.first
        try? state.modelContext?.save()
    }
}

// MARK: - Edit Photo Item

private enum EditPhoto: Identifiable {
    case existing(String)
    case new(Data)

    var id: String {
        switch self {
        case .existing(let name): return "f:\(name)"
        case .new(let data): return "n:\(data.hashValue)"
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
