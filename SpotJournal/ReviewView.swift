import SwiftUI

struct ReviewView: View {
    @Environment(AppState.self) private var state
    @State private var caption: String = ""
    @State private var currentPhoto = 0
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
                    state.screen = .camera
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Camera")
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
                    // Photos
                    if !state.pendingPhotos.isEmpty {
                        VStack(spacing: 14) {
                            TabView(selection: $currentPhoto) {
                                ForEach(Array(state.pendingPhotos.enumerated()), id: \.offset) { index, data in
                                    PhotoPasteView(
                                        photoSource: .data(data),
                                        width: 244, height: 288, rotation: -1.4,
                                        showTape: true, isDark: theme.isDark
                                    )
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: 344)

                            if state.pendingPhotos.count > 1 {
                                HStack(spacing: 6) {
                                    ForEach(0..<state.pendingPhotos.count, id: \.self) { i in
                                        Circle()
                                            .fill(i == currentPhoto ? theme.accent : theme.ink3.opacity(0.3))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }

                            photoStrip(theme: theme)
                        }
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

    // MARK: - Photo Strip (reorder / remove / add more)

    @ViewBuilder
    private func photoStrip(theme: JournalTheme) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(state.pendingPhotos.enumerated()), id: \.offset) { index, data in
                    ZStack(alignment: .topTrailing) {
                        if let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(index == currentPhoto ? theme.accent : theme.border1,
                                                lineWidth: index == currentPhoto ? 2 : 1)
                                )
                        }

                        Button {
                            removePhoto(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.white, .black.opacity(0.55))
                        }
                        .offset(x: 5, y: -5)
                    }
                    .onTapGesture {
                        withAnimation { currentPhoto = index }
                    }
                    .contextMenu {
                        if index > 0 {
                            Button { movePhoto(from: index, to: index - 1) } label: {
                                Label("Move Left", systemImage: "arrow.left")
                            }
                        }
                        if index < state.pendingPhotos.count - 1 {
                            Button { movePhoto(from: index, to: index + 1) } label: {
                                Label("Move Right", systemImage: "arrow.right")
                            }
                        }
                        Button(role: .destructive) {
                            removePhoto(at: index)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }

                // Add more
                if state.pendingPhotos.count < JournalEntry.maxPhotos {
                    Button {
                        state.screen = .camera
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.fg2)
                            .frame(width: 46, height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(theme.surfaceSunken)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(theme.border1, style: StrokeStyle(lineWidth: 1, dash: [3]))
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func removePhoto(at index: Int) {
        guard index < state.pendingPhotos.count else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        state.pendingPhotos.remove(at: index)
        if state.pendingPhotos.isEmpty {
            state.screen = .camera
            return
        }
        if currentPhoto >= state.pendingPhotos.count {
            currentPhoto = state.pendingPhotos.count - 1
        }
    }

    private func movePhoto(from: Int, to: Int) {
        guard from < state.pendingPhotos.count, to >= 0, to < state.pendingPhotos.count else { return }
        let item = state.pendingPhotos.remove(at: from)
        state.pendingPhotos.insert(item, at: to)
        currentPhoto = to
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
    @State private var showingCreateSection = false

    var body: some View {
        let theme = state.theme
        let existing = state.allTags

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Select tags")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.fg1)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Existing tags as pills
                    if !existing.isEmpty {
                        FlowLayout(spacing: 10) {
                            ForEach(existing) { tag in
                                let isSelected = selectedTags.contains { $0.id == tag.id }
                                TagPillButton(
                                    tag: tag,
                                    isSelected: isSelected,
                                    theme: theme,
                                    onTap: {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        if isSelected {
                                            selectedTags.removeAll { $0.id == tag.id }
                                        } else {
                                            selectedTags.append(tag)
                                        }
                                    },
                                    onEdit: {
                                        editingTagName = tag.name
                                        editingTag = tag
                                    },
                                    onDelete: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        selectedTags.removeAll { $0.id == tag.id }
                                        state.deleteTag(tag)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Text("No tags yet. Create one below!")
                            .font(.system(size: 14))
                            .foregroundColor(theme.fg3)
                            .padding(.horizontal, 20)
                    }
                    
                    // Create new tag section
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showingCreateSection.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showingCreateSection ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text(showingCreateSection ? "Cancel" : "Create New Tag")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(theme.accent)
                            .padding(.vertical, 8)
                        }
                        
                        if showingCreateSection {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Tag name", text: $newTagName)
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(theme.border2, lineWidth: 1)
                                            )
                                    )
                                
                                Text("Choose color")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.fg3)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<Tag.defaultColors.count, id: \.self) { i in
                                            Button {
                                                selectedColorIndex = i
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(hex: Tag.defaultColors[i]))
                                                        .frame(width: 32, height: 32)
                                                    
                                                    if selectedColorIndex == i {
                                                        Circle()
                                                            .stroke(theme.fg1, lineWidth: 2.5)
                                                            .frame(width: 38, height: 38)
                                                    }
                                                }
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 2)
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
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showingCreateSection = false
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Create Tag")
                                        }
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(theme.accent)
                                        )
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.border1, lineWidth: 1)
                                    )
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .background(theme.bg)
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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

// MARK: - Tag Pill Button

private struct TagPillButton: View {
    let tag: Tag
    let isSelected: Bool
    let theme: JournalTheme
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tag.color)
                    .frame(width: 10, height: 10)
                Text(tag.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? theme.fg1 : theme.fg2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? tag.color.opacity(0.2) : theme.surface)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? tag.color : theme.border1, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
    @State private var newMoodEmoji = "😊"
    @State private var newMoodColorIndex = 0
    @State private var editingMood: Mood?
    @State private var editingMoodName = ""
    @State private var editingMoodEmoji = ""
    @State private var showingCreateSection = false

    var body: some View {
        let theme = state.theme
        let existing = state.allMoods

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Select moods")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.fg1)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Existing moods as pills
                    if !existing.isEmpty {
                        FlowLayout(spacing: 10) {
                            ForEach(existing) { mood in
                                let isSelected = selectedMoods.contains { $0.id == mood.id }
                                MoodPillButton(
                                    mood: mood,
                                    isSelected: isSelected,
                                    theme: theme,
                                    onTap: {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        if isSelected {
                                            selectedMoods.removeAll { $0.id == mood.id }
                                        } else {
                                            selectedMoods.append(mood)
                                        }
                                    },
                                    onEdit: {
                                        editingMoodName = mood.name
                                        editingMoodEmoji = mood.emoji
                                        editingMood = mood
                                    },
                                    onDelete: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        selectedMoods.removeAll { $0.id == mood.id }
                                        state.deleteMood(mood)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Text("No moods yet. Create one below!")
                            .font(.system(size: 14))
                            .foregroundColor(theme.fg3)
                            .padding(.horizontal, 20)
                    }
                    
                    // Create new mood section
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showingCreateSection.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showingCreateSection ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text(showingCreateSection ? "Cancel" : "Create New Mood")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(theme.accent)
                            .padding(.vertical, 8)
                        }
                        
                        if showingCreateSection {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Mood name", text: $newMoodName)
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(theme.border2, lineWidth: 1)
                                            )
                                    )
                                
                                Text("Choose emoji")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.fg3)
                                
                                // Emoji palette
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 8) {
                                    ForEach(Mood.defaultEmojis, id: \.self) { emoji in
                                        Button {
                                            newMoodEmoji = emoji
                                        } label: {
                                            Text(emoji)
                                                .font(.system(size: 24))
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(newMoodEmoji == emoji ? theme.accentSoft : Color.clear)
                                                        .overlay(
                                                            Circle().stroke(
                                                                newMoodEmoji == emoji ? theme.accent : theme.border1,
                                                                lineWidth: newMoodEmoji == emoji ? 2 : 1
                                                            )
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    Text("Or type custom:")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.fg3)
                                    TextField("😀", text: $newMoodEmoji)
                                        .font(.system(size: 20))
                                        .frame(width: 50)
                                        .multilineTextAlignment(.center)
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(theme.border1, lineWidth: 1)
                                                )
                                        )
                                }
                                
                                Text("Choose color")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.fg3)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<Tag.defaultColors.count, id: \.self) { i in
                                            Button {
                                                newMoodColorIndex = i
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(hex: Tag.defaultColors[i]))
                                                        .frame(width: 32, height: 32)
                                                    
                                                    if newMoodColorIndex == i {
                                                        Circle()
                                                            .stroke(theme.fg1, lineWidth: 2.5)
                                                            .frame(width: 38, height: 38)
                                                    }
                                                }
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 2)
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
                                        newMoodEmoji = "😊"
                                        newMoodColorIndex = 0
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showingCreateSection = false
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Create Mood")
                                        }
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(theme.accent)
                                        )
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.border1, lineWidth: 1)
                                    )
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .background(theme.bg)
            .navigationTitle("Moods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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

// MARK: - Mood Pill Button

private struct MoodPillButton: View {
    let mood: Mood
    let isSelected: Bool
    let theme: JournalTheme
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 18))
                Text(mood.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? theme.fg1 : theme.fg2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? mood.color.opacity(0.2) : theme.surface)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? mood.color : theme.border1, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
