import SwiftUI

struct JournalPageView: View {
    let entry: JournalEntry
    var layout: LayoutStyle = .classic
    var captionFontStyle: CaptionFont = .serif
    let theme: JournalTheme

    @State private var showingPhotoZoom = false

    var body: some View {
        ZStack {
            switch layout {
            case .classic: classicLayout
            case .offset: offsetLayout
            case .split: splitLayout
            }
        }
        .fullScreenCover(isPresented: $showingPhotoZoom) {
            ZoomablePhotoViewer(photoSource: entry.photoSource, isPresented: $showingPhotoZoom)
        }
    }

    private var isZoomable: Bool {
        switch entry.photoSource {
        case .file, .data: return true
        case .placeholder: return false
        }
    }

    @ViewBuilder
    private func tagsAndMoodsView(centered: Bool) -> some View {
        VStack(spacing: 10) {
            // Tags row
            if !entry.tags.isEmpty {
                FlowLayout(spacing: 14) {
                    ForEach(entry.tags) { tag in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 7, height: 7)
                            Text(tag.name)
                                .font(.system(size: 12, design: .serif))
                                .tracking(0.2)
                                .foregroundColor(theme.ink2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            }
            
            // Moods row
            if !entry.moods.isEmpty {
                FlowLayout(spacing: 14) {
                    ForEach(entry.moods) { mood in
                        HStack(spacing: 5) {
                            Text(mood.emoji)
                                .font(.system(size: 11))
                            Text(mood.name)
                                .font(.system(size: 12, design: .serif))
                                .tracking(0.2)
                                .foregroundColor(theme.ink2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            }
        }
    }

    // MARK: - Classic Layout

    private var classicLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 44)

                PhotoPasteView(
                    photoSource: entry.photoSource,
                    width: 248, height: 290, rotation: -1.4,
                    showTape: true, isDark: theme.isDark
                )
                .onTapGesture { if isZoomable { showingPhotoZoom = true } }
                .padding(.bottom, 28)

                CaptionContentView(
                    text: entry.caption,
                    fontStyle: captionFontStyle,
                    fontSize: captionSize(for: captionFontStyle, base: 19),
                    theme: theme,
                    centered: true
                )
                .padding(.horizontal, 6)

                PageTimestampView(
                    date: entry.date, place: entry.place,
                    alignLeading: false, theme: theme
                )
                .padding(.top, 32)

                tagsAndMoodsView(centered: true)
                    .padding(.top, 14)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
        }
        .background(theme.paperBg)
    }

    // MARK: - Offset Layout

    private var offsetLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 44)

                PhotoPasteView(
                    photoSource: entry.photoSource,
                    width: 210, height: 250, rotation: -3.2,
                    showTape: true, isDark: theme.isDark
                )
                .onTapGesture { if isZoomable { showingPhotoZoom = true } }
                .padding(.leading, -6)
                .padding(.bottom, 28)

                CaptionContentView(
                    text: entry.caption,
                    fontStyle: captionFontStyle,
                    fontSize: captionSize(for: captionFontStyle, base: 19),
                    theme: theme
                )

                PageTimestampView(
                    date: entry.date, place: entry.place,
                    alignLeading: true, theme: theme
                )
                .padding(.top, 32)

                tagsAndMoodsView(centered: false)
                    .padding(.top, 14)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.paperBg)
    }

    // MARK: - Split Layout

    private var splitLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 44)

                PhotoPasteView(
                    photoSource: entry.photoSource,
                    width: 296, height: 300, rotation: 0.5,
                    showTape: false, isDark: theme.isDark
                )
                .onTapGesture { if isZoomable { showingPhotoZoom = true } }
                .padding(.bottom, 24)

                // Hairline rule
                Rectangle()
                    .fill(theme.ink3.opacity(0.2))
                    .frame(height: 1)
                    .padding(.bottom, 18)

                CaptionContentView(
                    text: entry.caption,
                    fontStyle: captionFontStyle,
                    fontSize: captionSize(for: captionFontStyle, base: 18),
                    theme: theme
                )

                PageTimestampView(
                    date: entry.date, place: entry.place,
                    alignLeading: true, theme: theme
                )
                .padding(.top, 28)

                tagsAndMoodsView(centered: false)
                    .padding(.top, 14)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .background(theme.paperBg)
    }
}
