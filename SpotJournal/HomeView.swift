import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    let entry: JournalEntry

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        let theme = state.theme

        ZStack {
            // Journal page
            JournalPageView(
                entry: entry,
                layout: state.layout,
                captionFontStyle: state.captionFont,
                theme: theme
            )

            // App header
            VStack {
                HStack {
                    // Placeholder keeps the title centered (browse now lives in the bottom bar)
                    Color.clear.frame(width: 36, height: 36)

                    Spacer()

                    Text(state.name.isEmpty ? "today" : "\(state.name)\u{2019}s journal")
                        .font(.system(size: 11, design: .serif))
                        .fontWeight(.medium)
                        .tracking(0.2)
                        .foregroundColor(theme.fg3)

                    Spacer()

                    IconChipButton(systemName: "gearshape", theme: theme) {
                        state.settingsOpen = true
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 8)

                Spacer()
            }

            // Saved toast
            if state.screen == .saved {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Saved.")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(theme.bg)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(theme.fg1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
                    .padding(.top, 60)

                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeOut(duration: 0.2), value: state.screen)
            }

            // Bottom action bar — View entries (70%) + Camera (30%)
            VStack(spacing: 12) {
                Spacer()

                if let pinned = state.pinnedEntry {
                    pinnedPill(pinned, theme: theme)
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Button {
                            state.screen = .browse
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 15, weight: .medium))
                                Text("View journals")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(theme.accent)
                            .frame(width: geo.size.width * 0.7, height: 58)
                            .background(theme.accentSoft)
                        }

                        Button {
                            state.screen = .camera
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22))
                                .foregroundColor(theme.fgOnAccent)
                                .frame(width: geo.size.width * 0.3, height: 58)
                                .background(theme.accent)
                        }
                    }
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(theme.border1, lineWidth: 1))
                    .shadow(color: Color(hex: 0x462D14).opacity(0.12), radius: 10, y: 6)
                }
                .frame(height: 58)
                .padding(.horizontal, 24)
                .padding(.bottom, 46)
            }
            .animation(.easeInOut(duration: 0.2), value: state.pinnedEntryId)
        }
    }

    /// Shortcut back to the pinned entry: tap to open, × to unpin.
    private func pinnedPill(_ pinned: JournalEntry, theme: JournalTheme) -> some View {
        HStack(spacing: 10) {
            Button {
                state.openPinned()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.accent)
                    Text(pinnedTitle(pinned))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.fg1)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Open pinned entry: \(pinnedTitle(pinned))")

            Button {
                state.togglePin(pinned.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.fg3)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Unpin")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(theme.border1, lineWidth: 1))
        )
    }

    /// First line of the caption, falling back to the place for caption-less entries.
    private func pinnedTitle(_ entry: JournalEntry) -> String {
        let firstLine = entry.caption
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
        if firstLine.isEmpty || firstLine == "\u{2014}" {
            return entry.place.isEmpty ? "Pinned entry" : entry.place
        }
        return firstLine
    }
}
