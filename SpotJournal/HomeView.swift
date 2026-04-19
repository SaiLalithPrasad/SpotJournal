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
                    IconChipButton(systemName: "square.grid.2x2", theme: theme) {
                        state.screen = .browse
                    }

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

            // Swipe hint
            VStack(spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))

                Text("swipe")
                    .font(.system(size: 9))
                    .tracking(0.3)
            }
            .foregroundColor(theme.fg4)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 10)

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

            // FAB — bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        state.screen = .camera
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.fgOnAccent)
                            .frame(width: 68, height: 68)
                            .background(
                                Circle()
                                    .fill(theme.accent)
                                    .shadow(
                                        color: theme.accent.opacity(0.4),
                                        radius: 14, y: 10
                                    )
                                    .shadow(
                                        color: Color(hex: 0x462D14).opacity(0.2),
                                        radius: 1, y: 1
                                    )
                            )
                    }
                    .padding(.trailing, 24)
                }
                .padding(.bottom, 46)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    if value.translation.width < -60 {
                        state.screen = .browse
                    }
                }
        )
    }
}
