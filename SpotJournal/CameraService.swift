import AVFoundation

@Observable
final class CameraService: NSObject {
    var isAuthorized = false
    var capturedPhotoData: Data?
    var flashEnabled = false
    var currentZoomLabel: String = "1x"
    var availableZoomPresets: [(label: String, factor: CGFloat)] = []

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.spotjournal.camera")
    private var currentPosition: AVCaptureDevice.Position = .back
    private var currentDevice: AVCaptureDevice?
    // The zoom factor that maps to "1x" (wide angle) on a multi-camera device
    private var wideAngleZoomFactor: CGFloat = 1.0

    func checkAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
    }

    func start() {
        guard isAuthorized else { return }
        sessionQueue.async { [self] in
            guard !session.isRunning else { return }
            configureSession()
            session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = flashEnabled ? .on : .off
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func flipCamera() {
        currentPosition = (currentPosition == .back) ? .front : .back
        sessionQueue.async { [self] in
            session.beginConfiguration()
            for input in session.inputs {
                session.removeInput(input)
            }
            let device = bestDevice(for: currentPosition)
            guard let device,
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            currentDevice = device
            session.commitConfiguration()
            let wideFactor = computeWideAngleZoomFactor(for: device)
            Task { @MainActor in
                self.wideAngleZoomFactor = wideFactor
                self.buildZoomPresets(for: device, wideFactor: wideFactor)
                self.setZoom(factor: wideFactor) // reset to 1x
            }
        }
    }

    func setZoom(factor: CGFloat) {
        guard let device = currentDevice else { return }
        let clamped = clampZoom(factor, for: device)
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
            } catch {}
        }
        updateZoomLabel(factor: clamped)
    }

    /// Smooth animated zoom — used by pinch gesture for native-feel transitions.
    func rampZoom(to factor: CGFloat, rate: Float = 4.0) {
        guard let device = currentDevice else { return }
        let clamped = clampZoom(factor, for: device)
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: clamped, withRate: rate)
                device.unlockForConfiguration()
            } catch {}
        }
        updateZoomLabel(factor: clamped)
    }

    /// Current raw zoom factor for use as pinch gesture anchor.
    var currentZoomFactor: CGFloat {
        currentDevice?.videoZoomFactor ?? wideAngleZoomFactor
    }

    // MARK: - Focus & Exposure

    /// Tap-to-focus at a normalized point (0...1 coordinate space of the preview).
    func focus(at point: CGPoint) {
        guard let device = currentDevice else { return }
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }

    // MARK: - Private

    /// Pick the best multi-camera device: triple > dual wide > wide
    private func bestDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if position == .back {
            // Try triple camera first (ultra-wide + wide + telephoto)
            if let triple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                return triple
            }
            // Then dual wide (ultra-wide + wide)
            if let dualWide = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                return dualWide
            }
        }
        // Fallback to wide angle
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    /// Compute the zoom factor that corresponds to "1x" (wide angle lens)
    private func computeWideAngleZoomFactor(for device: AVCaptureDevice) -> CGFloat {
        // On multi-camera devices, switchOverVideoZoomFactors tells us where
        // the lens transitions happen. The first switch point is typically
        // from ultra-wide to wide, so it represents the "1x" factor.
        if let firstSwitch = device.virtualDeviceSwitchOverVideoZoomFactors.first {
            return CGFloat(truncating: firstSwitch)
        }
        return 1.0
    }

    private func buildZoomPresets(for device: AVCaptureDevice, wideFactor: CGFloat) {
        var presets: [(label: String, factor: CGFloat)] = []
        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = device.maxAvailableVideoZoomFactor

        // 0.5x (ultra-wide) — only if device supports it
        let halfFactor = wideFactor * 0.5
        if halfFactor >= minZoom {
            presets.append(("0.5x", halfFactor))
        }

        // 1x (wide)
        presets.append(("1x", wideFactor))

        // 2x
        let twoFactor = wideFactor * 2
        if twoFactor <= maxZoom {
            presets.append(("2x", twoFactor))
        }

        availableZoomPresets = presets
    }

    private func clampZoom(_ factor: CGFloat, for device: AVCaptureDevice) -> CGFloat {
        min(max(factor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
    }

    private func updateZoomLabel(factor: CGFloat) {
        let display = factor / wideAngleZoomFactor
        if abs(display - 0.5) < 0.01 {
            currentZoomLabel = "0.5x"
        } else if abs(display - 1.0) < 0.01 {
            currentZoomLabel = "1x"
        } else if abs(display - 2.0) < 0.01 {
            currentZoomLabel = "2x"
        } else if abs(display - 3.0) < 0.01 {
            currentZoomLabel = "3x"
        } else {
            currentZoomLabel = String(format: "%.1fx", display)
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Video input — use best multi-camera device
        guard let device = bestDevice(for: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        currentDevice = device

        // Photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }

        session.commitConfiguration()

        // Set up zoom presets on main thread
        let wideFactor = computeWideAngleZoomFactor(for: device)
        Task { @MainActor in
            self.wideAngleZoomFactor = wideFactor
            self.buildZoomPresets(for: device, wideFactor: wideFactor)
            self.setZoom(factor: wideFactor) // default to 1x
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        Task { @MainActor in
            self.capturedPhotoData = data
        }
    }
}
