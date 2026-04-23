import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapping AVCaptureVideoPreviewLayer for the live camera feed.
/// Supports pinch-to-zoom and tap-to-focus via UIKit gesture recognizers.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var onTapToFocus: ((CGPoint, CGPoint) -> Void)?   // (devicePoint, viewPoint)
    var onPinchChanged: ((CGFloat) -> Void)?           // target zoom factor
    var pinchAnchorZoom: (() -> CGFloat)?              // current zoom at pinch start

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tap)

        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinch)

        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
        context.coordinator.onTapToFocus = onTapToFocus
        context.coordinator.onPinchChanged = onPinchChanged
        context.coordinator.pinchAnchorZoom = pinchAnchorZoom
    }

    class Coordinator: NSObject {
        var onTapToFocus: ((CGPoint, CGPoint) -> Void)?
        var onPinchChanged: ((CGFloat) -> Void)?
        var pinchAnchorZoom: (() -> CGFloat)?
        private var anchorZoom: CGFloat = 1.0

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? PreviewUIView else { return }
            let viewPoint = gesture.location(in: view)
            let devicePoint = view.previewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
            onTapToFocus?(devicePoint, viewPoint)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                anchorZoom = pinchAnchorZoom?() ?? 1.0
            case .changed:
                let targetZoom = anchorZoom * gesture.scale
                onPinchChanged?(targetZoom)
            default:
                break
            }
        }
    }

    /// Custom UIView that uses AVCaptureVideoPreviewLayer as its backing layer.
    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
