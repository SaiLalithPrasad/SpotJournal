import SwiftUI

struct PlaceholderPhoto: View {
    let photoKey: PhotoKey

    var body: some View {
        switch photoKey {
        case .window: WindowPhoto()
        case .coffee: CoffeePhoto()
        case .trail: TrailPhoto()
        case .plate: PlatePhoto()
        }
    }
}

// Warm sunset through a window frame
private struct WindowPhoto: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xF2C98E), Color(hex: 0xE29765), Color(hex: 0xA85A3D)],
                startPoint: .top, endPoint: .bottom
            )
            // Sun glow
            Circle()
                .fill(Color(hex: 0xFFE6B0).opacity(0.25))
                .frame(width: 128, height: 128)
                .offset(x: 50, y: -20)
            Circle()
                .fill(Color(hex: 0xFFE6B0).opacity(0.9))
                .frame(width: 84, height: 84)
                .offset(x: 50, y: -20)
            // Rooftops
            VStack(spacing: 0) {
                Spacer()
                WaveShape(heights: [0.6, 0.75, 0.55, 0.8, 0.5, 0.7])
                    .fill(Color(hex: 0x6B3E2A).opacity(0.8))
                    .frame(height: 120)
                    .offset(y: 40)
                WaveShape(heights: [0.4, 0.55, 0.3, 0.6, 0.35, 0.5])
                    .fill(Color(hex: 0x3E241B))
                    .frame(height: 90)
            }
            // Window cross
            Rectangle().fill(Color(hex: 0x2A1E18)).frame(width: 14)
            Rectangle().fill(Color(hex: 0x2A1E18)).frame(height: 14).offset(y: 10)
            Rectangle().stroke(Color(hex: 0x2A1E18), lineWidth: 12)
        }
    }
}

// Coffee cup on a warm background
private struct CoffeePhoto: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0xE8D4B0), Color(hex: 0x8A6A48)],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0, endRadius: 300
            )
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    // Saucer
                    Ellipse()
                        .fill(Color(hex: 0x3B2A1E).opacity(0.9))
                        .frame(width: 200, height: 50)
                        .offset(y: 50)
                    Ellipse()
                        .fill(Color(hex: 0xC8A574))
                        .frame(width: 180, height: 40)
                        .offset(y: 45)
                    // Cup body
                    CupShape()
                        .fill(Color(hex: 0xF1E3C9))
                        .frame(width: 140, height: 100)
                    // Coffee surface
                    Ellipse()
                        .fill(Color(hex: 0x2A180E))
                        .frame(width: 110, height: 20)
                        .offset(y: -38)
                }
                Spacer().frame(height: 80)
            }
        }
    }
}

// Mountain trail landscape
private struct TrailPhoto: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xD7C99E), Color(hex: 0xB89A66)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 0) {
                Spacer()
                WaveShape(heights: [0.5, 0.7, 0.4, 0.85, 0.55, 0.65])
                    .fill(Color(hex: 0x5E4A36).opacity(0.7))
                    .frame(height: 100)
                    .offset(y: 40)
                WaveShape(heights: [0.4, 0.6, 0.35, 0.75, 0.5, 0.55])
                    .fill(Color(hex: 0x3F3125).opacity(0.85))
                    .frame(height: 80)
                    .offset(y: 20)
                Rectangle()
                    .fill(Color(hex: 0x6D5438))
                    .frame(height: 100)
            }
            // Trail path
            TrailPath()
                .stroke(Color(hex: 0xD6B884), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 100, height: 160)
                .offset(y: 80)
            // Trees
            ForEach(0..<4, id: \.self) { i in
                TreeShape()
                    .fill(Color(hex: 0x1E2A1C))
                    .frame(width: 24, height: 36)
                    .offset(
                        x: [-80, 80, 60, -60][i],
                        y: [50, 45, 70, 65][i]
                    )
            }
        }
    }
}

// Pasta plate on dark table
private struct PlatePhoto: View {
    var body: some View {
        ZStack {
            Color(hex: 0x2B2620)
            Circle().fill(Color(hex: 0xEEE8D8)).frame(width: 240, height: 240)
            Circle().fill(Color(hex: 0xF8F2E2)).frame(width: 216, height: 216)
            Circle().fill(Color(hex: 0xD8A75A)).frame(width: 150, height: 150)
            // Tomatoes
            Circle().fill(Color(hex: 0xC73B35)).frame(width: 16).offset(x: -20, y: -15)
            Circle().fill(Color(hex: 0xC73B35)).frame(width: 14).offset(x: 20, y: 20)
            Circle().fill(Color(hex: 0xC73B35)).frame(width: 12).offset(x: 40, y: -10)
            // Basil
            Ellipse().fill(Color(hex: 0x3E6A2A)).frame(width: 20, height: 8)
                .rotationEffect(.degrees(20)).offset(x: -5, y: 5)
            Ellipse().fill(Color(hex: 0x3E6A2A)).frame(width: 16, height: 6)
                .rotationEffect(.degrees(-15)).offset(x: 25, y: 0)
        }
    }
}

// Camera viewfinder placeholder
struct ViewfinderPhoto: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xD8A868), Color(hex: 0x9A5E3C), Color(hex: 0x3A2218)],
                startPoint: .top, endPoint: .bottom
            )
            Circle()
                .fill(Color(hex: 0xFFD78A).opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: 60, y: -80)
            Circle()
                .fill(Color(hex: 0xFFE0A8).opacity(0.9))
                .frame(width: 100, height: 100)
                .offset(x: 60, y: -80)
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(Color(hex: 0x4A2E1D)).frame(height: 20)
                Rectangle().fill(Color(hex: 0x1E130C)).frame(height: 150)
            }
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0x6E3E26))
                .frame(width: 140, height: 42)
                .offset(y: 110)
        }
    }
}

// MARK: - Helper Shapes

private struct WaveShape: Shape {
    let heights: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard heights.count >= 2 else { return path }
        let step = rect.width / CGFloat(heights.count - 1)
        path.move(to: CGPoint(x: 0, y: rect.height * (1 - heights[0])))
        for i in 1..<heights.count {
            let x = step * CGFloat(i)
            let y = rect.height * (1 - heights[i])
            let prevY = rect.height * (1 - heights[i - 1])
            let cpx = step * (CGFloat(i) - 0.5)
            path.addQuadCurve(
                to: CGPoint(x: x, y: y),
                control: CGPoint(x: cpx, y: (prevY + y) / 2)
            )
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct CupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct TrailPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - 10, y: rect.midY),
            control: CGPoint(x: rect.midX + 15, y: rect.maxY * 0.7)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.midX - 25, y: rect.midY * 0.7)
        )
        return path
    }
}

private struct TreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
