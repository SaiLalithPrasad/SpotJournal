import SwiftUI
import PhotosUI

struct CameraView: View {
    @Environment(AppState.self) private var state
    @State private var cameraService = CameraService()
    @State private var locationService = LocationService()
    @State private var shutterFlash = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoadingPick = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live viewfinder or placeholder fallback
            if cameraService.isAuthorized {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
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

            // Shutter flash
            if shutterFlash {
                Color.white.opacity(0.85)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
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
                        Text("Tap to capture")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(0.2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.black.opacity(0.32)))
                    }

                    Spacer()

                    Button {
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
                                    cameraService.setZoom(factor: preset.factor)
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

                    // Shutter row
                    HStack {
                        // Gallery picker
                        PhotosPicker(selection: $pickerItem, matching: .images) {
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
                        .disabled(!cameraService.isAuthorized)

                        Spacer()

                        // Flip camera
                        Button {
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
            if let data = newData {
                state.pendingPhotoData = data
                state.pendingDate = Date()
                state.pendingPlace = locationService.currentPlace
                state.screen = .review
                cameraService.capturedPhotoData = nil
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            isLoadingPick = true
            Task {
                await handlePickedPhoto(newItem)
                isLoadingPick = false
                pickerItem = nil
            }
        }
    }

    private func shoot() {
        shutterFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            shutterFlash = false
            cameraService.capturePhoto()
        }
    }

    // MARK: - Gallery Pick

    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }

        // Extract EXIF metadata
        let metadata = PhotoMetadata.extract(from: data)

        state.pendingPhotoData = data
        state.pendingDate = metadata.date
        state.pendingPlace = ""

        // Reverse geocode if GPS coordinates are available
        if let lat = metadata.latitude, let lon = metadata.longitude {
            let place = await PhotoMetadata.reverseGeocode(latitude: lat, longitude: lon)
            state.pendingPlace = place
        }

        state.screen = .review
    }
}
