import SwiftUI
import UIKit

// MARK: - Photo Taped to Page

struct PhotoPasteView: View {
    let photoSource: PhotoSource
    var width: CGFloat = 232
    var height: CGFloat = 280
    var rotation: Double = -1.6
    var showTape: Bool = true
    let isDark: Bool

    var body: some View {
        ZStack {
            PhotoContentView(photoSource: photoSource)
                .frame(width: width, height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .shadow(
                    color: isDark ? .black.opacity(0.35) : Color(hex: 0x462D14).opacity(0.10),
                    radius: 2, y: 2
                )
                .shadow(
                    color: isDark ? .black.opacity(0.45) : Color(hex: 0x462D14).opacity(0.14),
                    radius: 12, y: 12
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(
                            isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.25),
                            lineWidth: 1
                        )
                )

            if showTape {
                TapeStrip(isDark: isDark)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -width * 0.2, y: -height / 2 - 2)

                TapeStrip(isDark: isDark)
                    .rotationEffect(.degrees(6))
                    .offset(x: width * 0.2, y: -height / 2 - 2)
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Photo Deck (single photo or swipeable carousel)

/// Renders a single taped photo, or — when an entry has multiple photos — a
/// horizontally swipeable carousel constrained to the photo frame, with page
/// dots and an "N/M" badge. Tapping a photo reports its index via `onTap`.
struct PhotoDeckView: View {
    let photoSources: [PhotoSource]
    var width: CGFloat = 248
    var height: CGFloat = 290
    var rotation: Double = -1.4
    var showTape: Bool = true
    let theme: JournalTheme
    var onTap: (Int) -> Void = { _ in }

    @State private var index = 0

    var body: some View {
        if photoSources.count <= 1 {
            PhotoPasteView(
                photoSource: photoSources.first ?? .placeholder(.window),
                width: width, height: height, rotation: rotation,
                showTape: showTape, isDark: theme.isDark
            )
            .onTapGesture { onTap(0) }
        } else {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    TabView(selection: $index) {
                        ForEach(Array(photoSources.enumerated()), id: \.offset) { i, source in
                            PhotoPasteView(
                                photoSource: source,
                                width: width, height: height, rotation: rotation,
                                showTape: showTape, isDark: theme.isDark
                            )
                            .onTapGesture { onTap(i) }
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(width: width + 28, height: height + 52)

                    Text("\(index + 1)/\(photoSources.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .padding(.top, 16)
                        .padding(.trailing, 10)
                }

                HStack(spacing: 6) {
                    ForEach(0..<photoSources.count, id: \.self) { i in
                        Circle()
                            .fill(i == index ? theme.ink2 : theme.ink3.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}

// MARK: - Photo Content (placeholder or real)

struct PhotoContentView: View {
    let photoSource: PhotoSource

    var body: some View {
        switch photoSource {
        case .placeholder(let key):
            PlaceholderPhoto(photoKey: key)
        case .file(let filename):
            if let uiImage = PhotoStore.load(filename) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        case .data(let imageData):
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
    }
}

// MARK: - Entry Thumbnail (for browse cards)

struct EntryThumbnailView: View {
    let entry: JournalEntry

    var body: some View {
        // Drive layout with a flexible base so the image's scaledToFill overflow
        // doesn't expand the container and shift the badge out of the clipped frame.
        Color.clear
            .overlay { thumbnail }
            .overlay(alignment: .topTrailing) {
                if entry.photoCount > 1 {
                    HStack(spacing: 3) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 8, weight: .semibold))
                        Text("\(entry.photoCount)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.5)))
                    .padding(6)
                }
            }
            .clipped()
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch entry.photoSource {
        case .file(let filename):
            AsyncThumbnailView(filename: filename)
        case .placeholder(let key):
            PlaceholderPhoto(photoKey: key)
        case .data(let data):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
    }
}

// MARK: - Async Thumbnail (loads on demand)

struct AsyncThumbnailView: View {
    let filename: String

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.15)
            }
        }
        .task(id: filename) {
            if let cached = ThumbnailCache.shared.image(for: filename) {
                self.image = cached
                return
            }
            let loaded = await Task.detached(priority: .utility) {
                let thumb = PhotoStore.loadThumbnail(filename)
                // Lazy-generate thumbnail for older entries
                PhotoStore.generateThumbnail(for: filename)
                return thumb
            }.value
            if let loaded {
                ThumbnailCache.shared.setImage(loaded, for: filename)
                self.image = loaded
            }
        }
    }
}

private struct TapeStrip: View {
    let isDark: Bool

    var body: some View {
        Rectangle()
            .fill(
                isDark
                    ? Color(hex: 0xB4965F).opacity(0.45)
                    : Color(hex: 0xE8D2A0).opacity(0.72)
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isDark ? 0.10 : 0.18),
                        Color.white.opacity(isDark ? 0.02 : 0.05),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 62, height: 18)
            .shadow(color: .black.opacity(isDark ? 0.3 : 0.08), radius: 1, y: 1)
    }
}

// MARK: - Page Timestamp

struct PageTimestampView: View {
    let date: Date
    let place: String
    var alignLeading: Bool = false
    let theme: JournalTheme

    var body: some View {
        VStack(alignment: alignLeading ? .leading : .center, spacing: 0) {
            // Hairline
            Rectangle()
                .fill(theme.ink3.opacity(0.25))
                .frame(height: 1)
                .frame(maxWidth: alignLeading ? .infinity : 120)
                .padding(.bottom, 12)

            // Date and time
            Text(formattedDate)
                .font(.system(size: 11, design: .serif))
                .fontWeight(.medium)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(theme.ink2)

            if !place.isEmpty {
                Text(place)
                    .font(.system(size: 10.5, design: .serif))
                    .fontWeight(.medium)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(theme.ink3)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignLeading ? .leading : .center)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let day = formatter.string(from: date)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: date).lowercased()
        return "\(day)  \u{00B7}  \(time)"
    }
}

// MARK: - Icon Chip Button

struct IconChipButton: View {
    let systemName: String
    let theme: JournalTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.fg1)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(theme.iconChipBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Zoomable Photo Viewer

/// Full-screen photo viewer. With a single photo it supports pinch-zoom, pan,
/// double-tap zoom, and swipe-down-to-dismiss. With multiple photos it becomes
/// a horizontal pager; each page supports pinch/double-tap zoom and pan-when-zoomed.
struct ZoomablePhotoViewer: View {
    let photoSources: [PhotoSource]
    var startIndex: Int = 0
    @Binding var isPresented: Bool

    @State private var index = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if photoSources.count <= 1 {
                ZoomablePhotoPage(
                    photoSource: photoSources.first ?? .placeholder(.window),
                    allowSwipeDownDismiss: true,
                    isPresented: $isPresented
                )
            } else {
                TabView(selection: $index) {
                    ForEach(Array(photoSources.enumerated()), id: \.offset) { i, source in
                        ZoomablePhotoPage(
                            photoSource: source,
                            allowSwipeDownDismiss: false,
                            isPresented: $isPresented
                        )
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    Text("\(index + 1) / \(photoSources.count)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.2)))
                        .padding(.bottom, 40)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.2)))
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .statusBarHidden()
        .onAppear { index = startIndex }
    }
}

/// A single zoomable/pannable photo page used by `ZoomablePhotoViewer`.
private struct ZoomablePhotoPage: View {
    let photoSource: PhotoSource
    var allowSwipeDownDismiss: Bool
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dismissOffset: CGFloat = 0

    /// Whether the drag gesture should be active. When inactive (multi-photo,
    /// unzoomed), drags fall through to the enclosing TabView so it can page.
    private var dragEnabled: Bool { allowSwipeDownDismiss || scale > 1 }

    var body: some View {
        if let uiImage = loadImage() {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .offset(y: dismissOffset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(magnifyGesture)
                .gesture(dragGesture, including: dragEnabled ? .all : .none)
                .onTapGesture(count: 2) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.25)) {
                        if scale > 1 { resetZoom() } else { scale = 3; lastScale = 3 }
                    }
                }
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in scale = max(1, lastScale * value.magnification) }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 { resetZoom() }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                } else if allowSwipeDownDismiss {
                    dismissOffset = value.translation.height
                }
            }
            .onEnded { _ in
                if scale > 1 {
                    lastOffset = offset
                } else if allowSwipeDownDismiss {
                    if abs(dismissOffset) > 100 {
                        isPresented = false
                    } else {
                        withAnimation(.spring(response: 0.3)) { dismissOffset = 0 }
                    }
                }
            }
    }

    private func resetZoom() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1; lastScale = 1
            offset = .zero; lastOffset = .zero
        }
    }

    private func loadImage() -> UIImage? {
        switch photoSource {
        case .file(let filename):
            return PhotoStore.load(filename)
        case .data(let data):
            return UIImage(data: data)
        case .placeholder:
            return nil
        }
    }
}

// MARK: - Caption Font Helper

func captionFont(for style: CaptionFont, size: CGFloat) -> Font {
    switch style {
    case .serif:
        return .system(size: size, design: .serif)
    case .sans:
        return .system(size: size, design: .default)
    case .hand:
        return .custom("Bradley Hand", size: size + 4)
    }
}

func captionLineSpacing(for style: CaptionFont) -> CGFloat {
    switch style {
    case .hand: return 2
    default: return 6
    }
}

func captionSize(for style: CaptionFont, base: CGFloat) -> CGFloat {
    switch style {
    case .hand: return base + 8
    default: return base
    }
}

// MARK: - Caption Block Parser

enum CaptionBlock {
    case prose(String)
    case bullet(String)
    case numbered(Int, String)
}

func parseCaptionBlocks(_ text: String) -> [CaptionBlock] {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var blocks: [CaptionBlock] = []
    var proseAccum: [String] = []

    func flushProse() {
        let joined = proseAccum.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !joined.isEmpty {
            blocks.append(.prose(joined))
        }
        proseAccum = []
    }

    for line in lines {
        if line.hasPrefix("- ") {
            flushProse()
            blocks.append(.bullet(String(line.dropFirst(2))))
        } else if let match = line.firstMatch(of: /^(\d+)\.\s+(.+)/) {
            flushProse()
            let num = Int(match.1) ?? 0
            blocks.append(.numbered(num, String(match.2)))
        } else {
            proseAccum.append(line)
        }
    }
    flushProse()
    return blocks
}

// MARK: - URL Detection

private func linkified(_ text: String) -> AttributedString {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
        return AttributedString(text)
    }

    let nsText = text as NSString
    let matches = detector.matches(in: text, range: NSRange(location: 0, length: nsText.length))
    guard !matches.isEmpty else { return AttributedString(text) }

    var result = AttributedString()
    var lastEnd = text.startIndex

    for match in matches {
        guard let url = match.url,
              let range = Range(match.range, in: text) else { continue }

        if lastEnd < range.lowerBound {
            result += AttributedString(text[lastEnd..<range.lowerBound])
        }

        var linkPart = AttributedString(text[range])
        linkPart.link = url
        result += linkPart

        lastEnd = range.upperBound
    }

    if lastEnd < text.endIndex {
        result += AttributedString(text[lastEnd..<text.endIndex])
    }

    return result
}

// MARK: - Caption Content View

struct CaptionContentView: View {
    let text: String
    let fontStyle: CaptionFont
    let fontSize: CGFloat
    let theme: JournalTheme
    var centered: Bool = false

    var body: some View {
        let blocks = parseCaptionBlocks(text)
        let allProse = blocks.allSatisfy { if case .prose = $0 { return true } else { return false } }

        Group {
            if allProse {
                Text(linkified(text))
                    .font(captionFont(for: fontStyle, size: fontSize))
                    .lineSpacing(captionLineSpacing(for: fontStyle))
                    .foregroundColor(theme.ink1)
                    .multilineTextAlignment(centered ? .center : .leading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        switch block {
                        case .prose(let str):
                            Text(linkified(str))
                                .font(captionFont(for: fontStyle, size: fontSize))
                                .lineSpacing(captionLineSpacing(for: fontStyle))
                                .foregroundColor(theme.ink1)
                                .multilineTextAlignment(centered ? .center : .leading)
                                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)

                        case .bullet(let item):
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\u{2022}")
                                    .font(.system(size: fontSize * 0.7))
                                    .foregroundColor(theme.ink2)
                                Text(linkified(item))
                                    .font(captionFont(for: fontStyle, size: fontSize * 0.92))
                                    .lineSpacing(captionLineSpacing(for: fontStyle))
                                    .foregroundColor(theme.ink1)
                            }

                        case .numbered(let n, let item):
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(n).")
                                    .font(captionFont(for: fontStyle, size: fontSize * 0.85))
                                    .foregroundColor(theme.ink2)
                                    .frame(width: 22, alignment: .trailing)
                                Text(linkified(item))
                                    .font(captionFont(for: fontStyle, size: fontSize * 0.92))
                                    .lineSpacing(captionLineSpacing(for: fontStyle))
                                    .foregroundColor(theme.ink1)
                            }
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}
