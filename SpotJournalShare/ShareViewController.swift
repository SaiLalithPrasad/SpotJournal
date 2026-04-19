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
        let imageFilename: String
        let date: Date?
        let latitude: Double?
        let longitude: Double?
        let caption: String
    }
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

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                        guard let self else { return }

                        var imageData: Data?
                        if let url = data as? URL {
                            imageData = try? Data(contentsOf: url)
                        } else if let d = data as? Data {
                            imageData = d
                        } else if let image = data as? UIImage {
                            imageData = image.jpegData(compressionQuality: 0.9)
                        }

                        guard let imageData else {
                            DispatchQueue.main.async { self.close() }
                            return
                        }

                        DispatchQueue.main.async {
                            self.showCaptionUI(imageData: imageData)
                        }
                    }
                    return
                }
            }
        }
        close()
    }

    private func showCaptionUI(imageData: Data) {
        let hostingController = UIHostingController(
            rootView: ShareCaptionView(
                imageData: imageData,
                onSave: { [weak self] caption, data in
                    self?.saveAndClose(caption: caption, imageData: data)
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

    private func saveAndClose(caption: String, imageData: Data) {
        let meta = extractEXIF(from: imageData)

        guard let pendingDir = SharedContainer.pendingDir else {
            close()
            return
        }
        try? FileManager.default.createDirectory(at: pendingDir, withIntermediateDirectories: true)

        let id = UUID().uuidString
        let imageFile = pendingDir.appendingPathComponent("\(id).jpg")
        try? imageData.write(to: imageFile)

        let entry = SharedContainer.PendingEntry(
            imageFilename: "\(id).jpg",
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
    let imageData: Data
    let onSave: (String, Data) -> Void
    let onCancel: () -> Void

    @State private var caption = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let uiImage = UIImage(data: imageData) {
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

                Text("Photo will be added to your journal with its original timestamp.")
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
                        onSave(caption.trimmingCharacters(in: .whitespacesAndNewlines), imageData)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
