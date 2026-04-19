import SwiftUI
import SwiftData

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
                    .transition(.move(edge: .trailing))

            case .entry(let id):
                EntryDetailView(initialEntryId: id)
                    .transition(.move(edge: .trailing))
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
            .ignoresSafeArea(edges: .bottom)

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

    var body: some View {
        let theme = state.theme

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photo preview
                    PhotoContentView(photoSource: entry.photoSource)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))

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
        }
        .onAppear {
            caption = entry.caption == "\u{2014}" ? "" : entry.caption
            selectedTags = entry.tags
            listMode = caption.contains("\n- ")
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
        try? state.modelContext?.save()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
