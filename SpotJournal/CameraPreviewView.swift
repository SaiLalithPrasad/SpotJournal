import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapping AVCaptureVideoPreviewLayer for the live camera feed.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    /// Custom UIView that uses AVCaptureVideoPreviewLayer as its backing layer.
    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        // Safe: layerClass override guarantees AVCaptureVideoPreviewLayer
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
