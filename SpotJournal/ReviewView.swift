import SwiftUI

struct ReviewView: View {
    @Environment(AppState.self) private var state
    @State private var caption: String = ""
    @State private var listMode = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTagSheet = false
    @State private var selectedMoods: [Mood] = []
    @State private var showingMoodSheet = false
    @FocusState private var captionFocused: Bool

    var body: some View {
        let theme = state.theme
        let fontStyle = state.captionFont

        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    state.pendingPhotoData = nil
                    state.screen = .camera
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text("Retake")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(theme.fg2)
                }

                Spacer()

                Text("new entry")
                    .font(.system(size: 10, design: .serif))
                    .fontWeight(.medium)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(theme.ink3)

                Spacer()

                Button {
                    state.savePage(caption: caption.trimmingCharacters(in: .whitespacesAndNewlines), tags: selectedTags, moods: selectedMoods)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(theme.fgOnAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(theme.accent))
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 0) {
                    // Photo
                    if let photoData = state.pendingPhotoData {
                        PhotoPasteView(
                            photoSource: .data(photoData),
                            width: 244, height: 288, rotation: -1.4,
                            showTape: true, isDark: theme.isDark
                        )
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }

                    // Caption input
                    TextField(
                        listMode ? "Add items, one per line\u{2026}" : "Write a few words about this moment\u{2026}",
                        text: $caption,
                        axis: .vertical
                    )
                    .font(captionFont(for: fontStyle, size: captionSize(for: fontStyle, base: 19)))
                    .lineSpacing(captionLineSpacing(for: fontStyle))
                    .foregroundColor(theme.ink1)
                    .multilineTextAlignment(listMode ? .leading : .center)
                    .focused($captionFocused)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 80)
                    .onChange(of: caption) { oldValue, newValue in
                        guard listMode else { return }
                        if newValue.hasSuffix("\n") && !oldValue.hasSuffix("\n") {
                            caption = newValue + "- "
                        }
                    }

                    // List mode toggle
                    HStack {
                        Spacer()
                        Button {
                            listMode.toggle()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 12, weight: .medium))
                                Text("List")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(listMode ? theme.accent : theme.fg2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(listMode ? theme.accentSoft : theme.surfaceSunken)
                                    .overlay(
                                        Capsule().stroke(listMode ? theme.accent.opacity(0.3) : theme.border1, lineWidth: 1)
                                    )
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // Tags
                    TagSelectorView(
                        selectedTags: $selectedTags,
                        showingTagSheet: $showingTagSheet,
                        theme: theme
                    )
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 12)

                    // Moods
                    MoodSelectorView(
                        selectedMoods: $selectedMoods,
                        showingMoodSheet: $showingMoodSheet,
                        theme: theme
                    )
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // Timestamp
                    PageTimestampView(
                        date: state.pendingDate ?? Date(),
                        place: state.pendingPlace,
                        alignLeading: false,
                        theme: theme
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(theme.paperBg)
        .sheet(isPresented: $showingTagSheet) {
            TagPickerSheet(selectedTags: $selectedTags)
                .environment(state)
        }
        .sheet(isPresented: $showingMoodSheet) {
            MoodPickerSheet(selectedMoods: $selectedMoods)
                .environment(state)
        }
        .onAppear {
            captionFocused = true
        }
    }
}

// MARK: - Tag Selector (inline chips + add button)

private struct TagSelectorView: View {
    @Binding var selectedTags: [Tag]
    @Binding var showingTagSheet: Bool
    let theme: JournalTheme

    var body: some View {
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
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if i > 0 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            if i > 0 { y += spacing }
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y + (rowHeight - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += rowHeight
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}

// MARK: - Tag Picker Sheet

struct TagPickerSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: [Tag]
    @State private var newTagName = ""
    @State private var selectedColorIndex = 0
    @State private var editingTag: Tag?
    @State private var editingTagName = ""

    var body: some View {
        let theme = state.theme

        NavigationStack {
            List {
                // Create new tag
                Section("Create Tag") {
                    TextField("Tag name", text: $newTagName)
                        .font(.system(size: 15))

                    // Color picker
                    HStack(spacing: 0) {
                        ForEach(0..<Tag.defaultColors.count, id: \.self) { i in
                            Button {
                                selectedColorIndex = i
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: Tag.defaultColors[i]))
                                        .frame(width: 28, height: 28)

                                    if selectedColorIndex == i {
                                        Circle()
                                            .stroke(theme.fg1, lineWidth: 2.5)
                                            .frame(width: 34, height: 34)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !newTagName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            let tag = state.createTag(
                                name: newTagName.trimmingCharacters(in: .whitespaces),
                                colorHex: Tag.defaultColors[selectedColorIndex]
                            )
                            selectedTags.append(tag)
                            newTagName = ""
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create \"\(newTagName.trimmingCharacters(in: .whitespaces))\"")
                            }
                            .foregroundColor(theme.accent)
                        }
                    }
                }

                // Existing tags
                let existing = state.allTags
                if !existing.isEmpty {
                    Section("Existing Tags") {
                        ForEach(existing) { tag in
                            let isSelected = selectedTags.contains { $0.id == tag.id }
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                if isSelected {
                                    selectedTags.removeAll { $0.id == tag.id }
                                } else {
                                    selectedTags.append(tag)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 12, height: 12)
                                    Text(tag.name)
                                        .font(.system(size: 15))
                                        .foregroundColor(theme.fg1)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(theme.accent)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    selectedTags.removeAll { $0.id == tag.id }
                                    state.deleteTag(tag)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingTagName = tag.name
                                    editingTag = tag
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .alert("Rename Tag", isPresented: .init(
            get: { editingTag != nil },
            set: { if !$0 { editingTag = nil } }
        )) {
            TextField("Tag name", text: $editingTagName)
            Button("Save") {
                if let tag = editingTag {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    state.renameTag(tag, to: editingTagName)
                }
                editingTag = nil
            }
            Button("Cancel", role: .cancel) {
                editingTag = nil
            }
        } message: {
            Text("Enter a new name for this tag.")
        }
    }
}

// MARK: - Mood Selector (inline chips + add button)

private struct MoodSelectorView: View {
    @Binding var selectedMoods: [Mood]
    @Binding var showingMoodSheet: Bool
    let theme: JournalTheme

    var body: some View {
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
}

// MARK: - Mood Picker Sheet

struct MoodPickerSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMoods: [Mood]
    @State private var newMoodName = ""
    @State private var newMoodEmoji = "\u{1F60A}"
    @State private var newMoodColorIndex = 0
    @State private var editingMood: Mood?
    @State private var editingMoodName = ""
    @State private var editingMoodEmoji = ""

    var body: some View {
        let theme = state.theme

        NavigationStack {
            List {
                // Create new mood
                Section("Create Mood") {
                    TextField("Mood name", text: $newMoodName)
                        .font(.system(size: 15))

                    // Emoji palette
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 6) {
                        ForEach(Mood.defaultEmojis, id: \.self) { emoji in
                            Button {
                                newMoodEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 22))
                                    .frame(width: 38, height: 38)
                                    .background(
                                        Circle()
                                            .fill(newMoodEmoji == emoji ? theme.accentSoft : Color.clear)
                                            .overlay(
                                                Circle().stroke(
                                                    newMoodEmoji == emoji ? theme.accent : Color.clear,
                                                    lineWidth: 2
                                                )
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("Custom:")
                            .font(.system(size: 13))
                            .foregroundColor(theme.fg3)
                        TextField("\u{1F600}", text: $newMoodEmoji)
                            .font(.system(size: 18))
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                    }

                    // Color picker
                    HStack(spacing: 0) {
                        ForEach(0..<Tag.defaultColors.count, id: \.self) { i in
                            Button {
                                newMoodColorIndex = i
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: Tag.defaultColors[i]))
                                        .frame(width: 28, height: 28)

                                    if newMoodColorIndex == i {
                                        Circle()
                                            .stroke(theme.fg1, lineWidth: 2.5)
                                            .frame(width: 34, height: 34)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !newMoodName.trimmingCharacters(in: .whitespaces).isEmpty
                        && !newMoodEmoji.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            let mood = state.createMood(
                                name: newMoodName.trimmingCharacters(in: .whitespaces),
                                emoji: newMoodEmoji.trimmingCharacters(in: .whitespaces),
                                colorHex: Tag.defaultColors[newMoodColorIndex]
                            )
                            selectedMoods.append(mood)
                            newMoodName = ""
                            newMoodEmoji = "\u{1F60A}"
                            newMoodColorIndex = 0
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create \(newMoodEmoji) \"\(newMoodName.trimmingCharacters(in: .whitespaces))\"")
                            }
                            .foregroundColor(theme.accent)
                        }
                    }
                }

                // Existing moods
                let existing = state.allMoods
                if !existing.isEmpty {
                    Section("Existing Moods") {
                        ForEach(existing) { mood in
                            let isSelected = selectedMoods.contains { $0.id == mood.id }
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                if isSelected {
                                    selectedMoods.removeAll { $0.id == mood.id }
                                } else {
                                    selectedMoods.append(mood)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(mood.color.opacity(0.18))
                                            .frame(width: 32, height: 32)
                                        Text(mood.emoji)
                                            .font(.system(size: 18))
                                    }
                                    Text(mood.name)
                                        .font(.system(size: 15))
                                        .foregroundColor(theme.fg1)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(theme.accent)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    selectedMoods.removeAll { $0.id == mood.id }
                                    state.deleteMood(mood)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingMoodName = mood.name
                                    editingMoodEmoji = mood.emoji
                                    editingMood = mood
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Moods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .alert("Edit Mood", isPresented: .init(
            get: { editingMood != nil },
            set: { if !$0 { editingMood = nil } }
        )) {
            TextField("Mood name", text: $editingMoodName)
            TextField("Emoji", text: $editingMoodEmoji)
            Button("Save") {
                if let mood = editingMood {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    state.renameMood(mood, to: editingMoodName)
                    state.updateMoodEmoji(mood, to: editingMoodEmoji)
                }
                editingMood = nil
            }
            Button("Cancel", role: .cancel) {
                editingMood = nil
            }
        } message: {
            Text("Update the name and emoji for this mood.")
        }
    }
}
