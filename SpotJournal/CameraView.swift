import SwiftUI
import PhotosUI

struct CameraView: View {
    @Environment(AppState.self) private var state
    @State private var cameraService = CameraService()
    @State private var locationService = LocationService()
    @State private var shutterFlash = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoadingPick = false
    @State private var focusPoint: CGPoint = .zero
    @State private var showFocusIndicator = false
    @State private var focusScale: CGFloat = 1.0
    @State private var focusHideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live viewfinder or placeholder fallback
            if cameraService.isAuthorized {
                CameraPreviewView(
                    session: cameraService.session,
                    onTapToFocus: { devicePoint, viewPoint in
                        cameraService.focus(at: devicePoint)
                        focusPoint = viewPoint
                        showFocusIndicator = true
                        focusScale = 1.4
                        withAnimation(.easeOut(duration: 0.2)) {
                            focusScale = 1.0
                        }
                        focusHideTask?.cancel()
                        focusHideTask = Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            guard !Task.isCancelled else { return }
                            withAnimation(.easeOut(duration: 0.3)) {
                                showFocusIndicator = false
                            }
                        }
                    },
                    onPinchChanged: { factor in
                        cameraService.setZoom(factor: factor)
                    },
                    pinchAnchorZoom: {
                        cameraService.currentZoomFactor
                    }
                )
                .ignoresSafeArea()
                .overlay {
                    if showFocusIndicator {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.yellow, lineWidth: 1.5)
                            .frame(width: 70, height: 70)
                            .scaleEffect(focusScale)
                            .position(focusPoint)
                            .allowsHitTesting(false)
                    }
                }
            } else {
                ViewfinderPhoto()
                    .ignoresSafeArea()
            }

            // Vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.35)],
                center: .center,
                startRadius: 150, endRadius: 400
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Shutter flash
            if shutterFlash {
                Color.white.opacity(0.85)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        state.pendingPhotos = []
                        state.screen = .home
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(.black.opacity(0.35)))
                    }

                    Spacer()

                    if !cameraService.isAuthorized {
                        Text("Camera access required")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.black.opacity(0.32)))
                    } else {
                        Text(captureHint)
                            .font(.system(size: 13, weight: .medium))
                            .tracking(0.2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.black.opacity(0.32)))
                    }

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        cameraService.flashEnabled.toggle()
                    } label: {
                        Image(systemName: cameraService.flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(cameraService.flashEnabled ? Color(hex: 0xFFD882) : .white)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(.black.opacity(0.35)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)

                Spacer()

                // Bottom controls
                VStack(spacing: 20) {
                    // Zoom presets
                    if cameraService.availableZoomPresets.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(cameraService.availableZoomPresets, id: \.factor) { preset in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    cameraService.rampZoom(to: preset.factor)
                                } label: {
                                    Text(preset.label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(
                                            cameraService.currentZoomLabel == preset.label
                                            ? Color(hex: 0xFFD882) : .white.opacity(0.85)
                                        )
                                        .frame(width: 40, height: 28)
                                        .background(
                                            Capsule().fill(
                                                cameraService.currentZoomLabel == preset.label
                                                ? .white.opacity(0.18) : .clear
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.35)))
                    }

                    // Captured photo tray
                    if !state.pendingPhotos.isEmpty {
                        photoTray
                    }

                    // Shutter row
                    HStack {
                        // Gallery picker
                        PhotosPicker(
                            selection: $pickerItems,
                            maxSelectionCount: max(1, JournalEntry.maxPhotos - state.pendingPhotos.count),
                            matching: .images
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: 0x28190F).opacity(0.6))
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                                if isLoadingPick {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .frame(width: 40, height: 40)
                        }
                        .disabled(isAtCapacity)
                        .opacity(isAtCapacity ? 0.4 : 1)

                        Spacer()

                        // Shutter button
                        Button {
                            shoot()
                        } label: {
                            Circle()
                                .fill(.white)
                                .frame(width: 66, height: 66)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: 5)
                                        .frame(width: 76, height: 76)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.3), lineWidth: 3)
                                        .frame(width: 82, height: 82)
                                )
                        }
                        .disabled(!cameraService.isAuthorized || isAtCapacity)
                        .opacity(isAtCapacity ? 0.4 : 1)

                        Spacer()

                        // Flip camera
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            cameraService.flipCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.black.opacity(0.35)))
                        }
                    }
                    .padding(.horizontal, 24)

                    // Continue to review
                    if !state.pendingPhotos.isEmpty {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            state.screen = .review
                        } label: {
                            HStack(spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("\(state.pendingPhotos.count)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 22, minHeight: 22)
                                    .background(Circle().fill(.black.opacity(0.85)))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 13)
                            .background(Capsule().fill(.white))
                        }
                    }
                }
                .padding(.bottom, 56)
            }
        }
        .task {
            await cameraService.checkAuthorization()
            cameraService.start()
            locationService.requestPermission()
            locationService.startUpdating()
        }
        .onDisappear {
            cameraService.stop()
            locationService.stopUpdating()
        }
        .onChange(of: cameraService.capturedPhotoData) { _, newData in
            guard let data = newData else { return }
            addCameraPhoto(data)
            cameraService.capturedPhotoData = nil
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            isLoadingPick = true
            Task {
                await handlePickedPhotos(newItems)
                isLoadingPick = false
                pickerItems = []
            }
        }
    }

    // MARK: - Tray

    private var photoTray: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(state.pendingPhotos.enumerated()), id: \.offset) { index, data in
                    ZStack(alignment: .topTrailing) {
                        if let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.white.opacity(0.5), lineWidth: 1)
                                )
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            guard index < state.pendingPhotos.count else { return }
                            state.pendingPhotos.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(.white, .black.opacity(0.6))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
        }
    }

    // MARK: - Helpers

    private var isAtCapacity: Bool {
        state.pendingPhotos.count >= JournalEntry.maxPhotos
    }

    private var captureHint: String {
        state.pendingPhotos.isEmpty
            ? "Tap to capture"
            : "\(state.pendingPhotos.count) of \(JournalEntry.maxPhotos)"
    }

    /// Appends a freshly captured camera photo, seeding date/place if it's the first.
    private func addCameraPhoto(_ data: Data) {
        guard state.pendingPhotos.count < JournalEntry.maxPhotos else { return }
        let wasEmpty = state.pendingPhotos.isEmpty
        state.pendingPhotos.append(data)
        if wasEmpty {
            state.pendingDate = Date()
            state.pendingPlace = locationService.currentPlace
        }
    }

    private func shoot() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        shutterFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            shutterFlash = false
            cameraService.capturePhoto()
        }
    }

    // MARK: - Gallery Pick

    private func handlePickedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard state.pendingPhotos.count < JournalEntry.maxPhotos else { break }
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }

            let wasEmpty = state.pendingPhotos.isEmpty
            state.pendingPhotos.append(data)

            // The entry has a single date/place — seed it from the first photo added.
            if wasEmpty {
                let metadata = PhotoMetadata.extract(from: data)
                state.pendingDate = metadata.date
                state.pendingPlace = ""
                if let lat = metadata.latitude, let lon = metadata.longitude {
                    let place = await PhotoMetadata.reverseGeocode(latitude: lat, longitude: lon)
                    state.pendingPlace = place
                }
            }
        }
    }
}
