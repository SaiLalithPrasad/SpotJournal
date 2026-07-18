import UIKit
import SwiftUI
import UniformTypeIdentifiers
import ImageIO

// MARK: - Shared Container (duplicated for extension target)

private enum SharedContainer {
    static let appGroupID = "group.spotjournal.shared"

    static var pendingDir: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return nil }
        return container.appendingPathComponent("pending", isDirectory: true)
    }

    struct PendingEntry: Codable {
        let imageFilenames: [String]
        let date: Date?
        let latitude: Double?
        let longitude: Double?
        let caption: String
    }

    /// Maximum photos accepted per shared entry (mirrors JournalEntry.maxPhotos).
    static let maxPhotos = 10
}

// MARK: - Share View Controller

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        handleIncomingItems()
    }

    private func handleIncomingItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        let providers = extensionItems
            .compactMap { $0.attachments }
            .flatMap { $0 }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
            .prefix(SharedContainer.maxPhotos)

        guard !providers.isEmpty else {
            close()
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        // Keep order stable by writing into a pre-sized array by index.
        var images = [Data?](repeating: nil, count: providers.count)

        for (index, provider) in providers.enumerated() {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { data, _ in
                var imageData: Data?
                if let url = data as? URL {
                    imageData = try? Data(contentsOf: url)
                } else if let d = data as? Data {
                    imageData = d
                } else if let image = data as? UIImage {
                    imageData = image.jpegData(compressionQuality: 0.9)
                }
                lock.lock()
                images[index] = imageData
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let loaded = images.compactMap { $0 }
            if loaded.isEmpty {
                self.close()
            } else {
                self.showCaptionUI(images: loaded)
            }
        }
    }

    private func showCaptionUI(images: [Data]) {
        let hostingController = UIHostingController(
            rootView: ShareCaptionView(
                images: images,
                onSave: { [weak self] caption, datas in
                    self?.saveAndClose(caption: caption, images: datas)
                },
                onCancel: { [weak self] in
                    self?.close()
                }
            )
        )
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }

    private func saveAndClose(caption: String, images: [Data]) {
        guard let first = images.first else { close(); return }
        // Use the first image's EXIF for the entry's date/location.
        let meta = extractEXIF(from: first)

        guard let pendingDir = SharedContainer.pendingDir else {
            close()
            return
        }
        try? FileManager.default.createDirectory(at: pendingDir, withIntermediateDirectories: true)

        let id = UUID().uuidString
        var filenames: [String] = []
        for (index, data) in images.enumerated() {
            let name = "\(id)_\(index).jpg"
            let imageFile = pendingDir.appendingPathComponent(name)
            do {
                try data.write(to: imageFile)
                filenames.append(name)
            } catch {
                continue
            }
        }

        guard !filenames.isEmpty else { close(); return }

        let entry = SharedContainer.PendingEntry(
            imageFilenames: filenames,
            date: meta.date,
            latitude: meta.latitude,
            longitude: meta.longitude,
            caption: caption
        )
        let metaFile = pendingDir.appendingPathComponent("\(id).json")
        try? JSONEncoder().encode(entry).write(to: metaFile)

        close()
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    // MARK: - EXIF extraction

    private struct EXIFResult {
        var date: Date?
        var latitude: Double?
        var longitude: Double?
    }

    private func extractEXIF(from data: Data) -> EXIFResult {
        var result = EXIFResult()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return result
        }

        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateStr = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            result.date = formatter.date(from: dateStr)
        }

        if let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
           let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
           let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
            result.latitude = latRef == "S" ? -lat : lat
            result.longitude = lonRef == "W" ? -lon : lon
        }

        return result
    }
}

// MARK: - Caption UI

private struct ShareCaptionView: View {
    let images: [Data]
    let onSave: (String, [Data]) -> Void
    let onCancel: () -> Void

    @State private var caption = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if images.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(images.enumerated()), id: \.offset) { _, data in
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 260)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 268)
                } else if let uiImage = images.first.flatMap({ UIImage(data: $0) }) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                }

                TextField("Add a caption\u{2026}", text: $caption, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Text(images.count > 1
                     ? "\(images.count) photos will be added to your journal as one entry."
                     : "Photo will be added to your journal with its original timestamp.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Add to Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(caption.trimmingCharacters(in: .whitespacesAndNewlines), images)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
