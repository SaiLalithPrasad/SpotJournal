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

struct ZoomablePhotoViewer: View {
    let photoSource: PhotoSource
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dismissOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black
                .opacity(1.0 - min(abs(dismissOffset) / 300, 0.5))
                .ignoresSafeArea()

            if let uiImage = loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .offset(y: dismissOffset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = max(1, lastScale * value.magnification)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 { resetZoom() }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        } else {
                                            dismissOffset = value.translation.height
                                        }
                                    }
                                    .onEnded { _ in
                                        if scale > 1 {
                                            lastOffset = offset
                                            if scale <= 1 {
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    offset = .zero; lastOffset = .zero
                                                }
                                            }
                                        } else {
                                            if abs(dismissOffset) > 100 {
                                                isPresented = false
                                            } else {
                                                withAnimation(.spring(response: 0.3)) {
                                                    dismissOffset = 0
                                                }
                                            }
                                        }
                                    }
                            )
                    )
                    .onTapGesture(count: 2) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeOut(duration: 0.25)) {
                            if scale > 1 {
                                resetZoom()
                            } else {
                                scale = 3; lastScale = 3
                            }
                        }
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
            .opacity(1.0 - min(abs(dismissOffset) / 200, 0.8))
        }
        .statusBarHidden()
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
