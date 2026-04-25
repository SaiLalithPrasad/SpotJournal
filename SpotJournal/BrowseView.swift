import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(AppState.self) private var state
    @State private var calendarOpen = false
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var searchText = ""
    @State private var selectedFilterTags: [Tag] = []
    @State private var entryToDelete: JournalEntry?

    var body: some View {
        let theme = state.theme
        let filtered = filteredEntries
        let groups = groupEntries(filtered)

        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    state.screen = .home
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.fg1)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(theme.surfaceSunken))
                }

                Spacer()

                Text("Entries")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .tracking(-0.3)
                    .foregroundColor(theme.fg1)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeOut(duration: 0.16)) {
                            calendarOpen.toggle()
                            if !calendarOpen {
                                selectedDate = nil
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(calendarOpen ? theme.accent : theme.fg1)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(calendarOpen ? theme.accentSoft : theme.surfaceSunken)
                            )
                    }

                    Button {
                        state.settingsOpen = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.fg1)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(theme.surfaceSunken))
                    }
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .background(theme.bg)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(theme.fg3)
                TextField("Search captions, places, or tags\u{2026}", text: $searchText)
                    .font(.system(size: 15))
                    .foregroundColor(theme.fg1)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.fg3)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surfaceSunken)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Active filter chips
            if selectedDate != nil || !selectedFilterTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Date chip
                        if let date = selectedDate {
                            HStack(spacing: 4) {
                                Text(dateChipLabel(date))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.accent)
                                Button {
                                    withAnimation(.easeOut(duration: 0.12)) {
                                        selectedDate = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(theme.fg3)
                                        .frame(width: 22, height: 22)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(.leading, 12)
                            .padding(.trailing, 4)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.accentSoft))
                        }

                        // Tag chips
                        ForEach(selectedFilterTags) { tag in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 8, height: 8)
                                Text(tag.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.fg1)
                                Button {
                                    withAnimation(.easeOut(duration: 0.12)) {
                                        selectedFilterTags.removeAll { $0.id == tag.id }
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
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
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }

            // Tag filter bar
            if !state.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(state.allTags) { tag in
                            let isSelected = selectedFilterTags.contains { $0.id == tag.id }
                            Button {
                                withAnimation(.easeOut(duration: 0.12)) {
                                    if isSelected {
                                        selectedFilterTags.removeAll { $0.id == tag.id }
                                    } else {
                                        selectedFilterTags.append(tag)
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 8, height: 8)
                                    Text(tag.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(isSelected ? theme.fg1 : theme.fg3)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(isSelected ? tag.color.opacity(0.15) : theme.surfaceSunken)
                                        .overlay(
                                            Capsule().stroke(
                                                isSelected ? tag.color.opacity(0.3) : theme.border1,
                                                lineWidth: 1
                                            )
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }

            Rectangle().fill(theme.border1).frame(height: 1)

            // Calendar
            if calendarOpen {
                VStack(spacing: 0) {
                    MiniCalendarView(
                        entries: state.entries,
                        selectedDate: $selectedDate,
                        currentMonth: $currentMonth,
                        theme: theme
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Text("Tap a dot to filter by day.")
                        .font(.system(size: 11))
                        .foregroundColor(theme.fg3)
                        .padding(.bottom, 8)
                }
                .background(theme.bgAlt)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(theme.border1).frame(height: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Entry count
            if !filtered.isEmpty {
                HStack(spacing: 6) {
                    Text("\(filtered.count) \(filtered.count == 1 ? "entry" : "entries")")
                    if !state.name.isEmpty {
                        Text("|")
                        Text("\(state.name)'s journal")
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(theme.fg3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            // Entry list
            if filtered.isEmpty {
                VStack {
                    Spacer()
                    Text(state.entries.isEmpty ? "Nothing yet. Shoot your first." : "No entries match your search.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.fg3)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(groups, id: \.label) { group in
                        Section {
                            ForEach(group.items) { entry in
                                EntryCardView(entry: entry, theme: theme) {
                                    state.screen = .entry(entry.id)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        entryToDelete = entry
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text(group.label)
                                .font(.system(size: 10, weight: .medium))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundColor(theme.fg3)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 16))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(theme.bg)
        .alert("Delete Entry?", isPresented: .init(
            get: { entryToDelete != nil },
            set: { if !$0 { entryToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                    entryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text("This entry and its photo will be permanently deleted.")
        }
        .onAppear {
            if let first = state.entries.first {
                let cal = Calendar.current
                currentMonth = cal.date(from: cal.dateComponents([.year, .month], from: first.date)) ?? Date()
            }
        }
    }

    // MARK: - Filtering

    private var filteredEntries: [JournalEntry] {
        var result = state.entries.sorted { $0.date > $1.date }

        // Filter by selected date
        if let date = selectedDate {
            result = result.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }

        // Filter by selected tags (entry must have ALL selected tags)
        if !selectedFilterTags.isEmpty {
            let tagIDs = Set(selectedFilterTags.map(\.id))
            result = result.filter { entry in
                let entryTagIDs = Set(entry.tags.map(\.id))
                return tagIDs.isSubset(of: entryTagIDs)
            }
        }

        // Filter by search text (captions, places, and tag names)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { entry in
                entry.caption.lowercased().contains(query) ||
                entry.place.lowercased().contains(query) ||
                entry.tags.contains { $0.name.lowercased().contains(query) }
            }
        }

        return result
    }

    private func groupEntries(_ entries: [JournalEntry]) -> [EntryGroup] {
        var groups: [EntryGroup] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var current: EntryGroup?
        for entry in entries {
            let label = formatter.string(from: entry.date)
            if current?.label != label {
                if let c = current { groups.append(c) }
                current = EntryGroup(label: label, items: [])
            }
            current?.items.append(entry)
        }
        if let c = current { groups.append(c) }
        return groups
    }

    private func dateChipLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func deleteEntry(_ entry: JournalEntry) {
        guard let context = state.modelContext else { return }
        if let filename = entry.photoFileName {
            PhotoStore.delete(filename)
        }
        context.delete(entry)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private struct EntryGroup {
    let label: String
    var items: [JournalEntry]
}

// MARK: - Entry Card

private struct EntryCardView: View {
    let entry: JournalEntry
    let theme: JournalTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                EntryThumbnailView(entry: entry)
                    .frame(width: 76, height: 92)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .shadow(color: Color(hex: 0x462D14).opacity(0.08), radius: 5, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    // Date
                    Text(dateLabel)
                        .font(.system(size: 11, design: .serif))
                        .fontWeight(.medium)
                        .tracking(0.5)
                        .foregroundColor(theme.fg2)

                    // Caption preview
                    Text(entry.caption)
                        .font(.system(size: 15, design: .serif))
                        .tracking(-0.1)
                        .lineSpacing(2)
                        .foregroundColor(theme.fg1)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Place
                    if !entry.place.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9))
                            Text(entry.place)
                                .lineLimit(1)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(theme.fg3)
                        .padding(.top, 2)
                    }

                    // Tags
                    if !entry.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(entry.tags.prefix(3)) { tag in
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 6, height: 6)
                                    Text(tag.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(theme.fg2)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(tag.color.opacity(0.1))
                                )
                            }
                            if entry.tags.count > 3 {
                                Text("+\(entry.tags.count - 3)")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.fg3)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.border1, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let date = formatter.string(from: entry.date)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: entry.date).lowercased()
        return "\(date) \u{00B7} \(time)"
    }
}

// MARK: - Mini Calendar

private struct MiniCalendarView: View {
    let entries: [JournalEntry]
    @Binding var selectedDate: Date?
    @Binding var currentMonth: Date
    let theme: JournalTheme

    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Month header
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.fg1)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(theme.surfaceSunken))
                }

                Spacer()

                Text(monthLabel)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .tracking(-0.2)
                    .foregroundColor(theme.fg1)

                Spacer()

                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.fg1)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(theme.surfaceSunken))
                }
            }
            .padding(.bottom, 10)

            // Day of week headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9.5, weight: .medium))
                        .tracking(0.1)
                        .textCase(.uppercase)
                        .foregroundColor(theme.fg3)
                        .frame(height: 20)
                }
            }
            .padding(.bottom, 4)

            // Day cells
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(dayCells, id: \.offset) { cell in
                    if let day = cell.day {
                        let hasEntry = entryDays.contains(day)
                        let isSelected = selectedDate.map { isSameDay($0, dayDate(day)) } ?? false
                        let isToday = isSameDay(Date(), dayDate(day))

                        Button {
                            if hasEntry {
                                selectedDate = dayDate(day)
                            }
                        } label: {
                            ZStack {
                                if isSelected {
                                    Circle().fill(theme.accent)
                                }

                                Text("\(day)")
                                    .font(.system(size: 13, weight: isSelected || isToday ? .semibold : .regular))
                                    .foregroundColor(
                                        isSelected ? theme.fgOnAccent :
                                        hasEntry ? theme.fg1 : theme.fg4
                                    )

                                if hasEntry && !isSelected {
                                    Circle()
                                        .fill(theme.accent)
                                        .frame(width: 4, height: 4)
                                        .offset(y: 10)
                                }

                                if isToday && !isSelected {
                                    Circle()
                                        .stroke(theme.border2, lineWidth: 1.5)
                                        .padding(2)
                                }
                            }
                        }
                        .disabled(!hasEntry)
                        .frame(height: 32)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.border1, lineWidth: 1)
                )
        )
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func changeMonth(_ delta: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private var entryDays: Set<Int> {
        let cal = Calendar.current
        let year = cal.component(.year, from: currentMonth)
        let month = cal.component(.month, from: currentMonth)
        var days = Set<Int>()
        for entry in entries {
            let ey = cal.component(.year, from: entry.date)
            let em = cal.component(.month, from: entry.date)
            if ey == year && em == month {
                days.insert(cal.component(.day, from: entry.date))
            }
        }
        return days
    }

    private struct DayCell: Identifiable {
        let offset: Int
        let day: Int?
        var id: Int { offset }
    }

    private var dayCells: [DayCell] {
        let cal = Calendar.current
        let year = cal.component(.year, from: currentMonth)
        let month = cal.component(.month, from: currentMonth)

        guard let firstOfMonth = cal.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1
        var cells: [DayCell] = []
        for i in 0..<firstWeekday {
            cells.append(DayCell(offset: i, day: nil))
        }
        for day in range {
            cells.append(DayCell(offset: firstWeekday + day - 1, day: day))
        }
        while cells.count % 7 != 0 {
            cells.append(DayCell(offset: cells.count, day: nil))
        }
        return cells
    }

    private func dayDate(_ day: Int) -> Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: currentMonth)
        let month = cal.component(.month, from: currentMonth)
        return cal.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }
}
