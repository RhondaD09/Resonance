//
//  MoodSelectionView.swift
//  Resonance

import SwiftUI
// MARK: - 3D Parallax / Gyroscope (commented out — pending team lead decision)
//import CoreMotion  // ← needed for gyroscope
//import Combine     // ← needed for @Published / ObservableObject
//
////Gyroscope Manager
//// This class reads your device's tilt and publishes it as (x, y) values
//
//class MotionManager: ObservableObject {
//    private let manager = CMMotionManager()
//
//    @Published var tiltX: CGFloat = 0  // left/right tilt
//    @Published var tiltY: CGFloat = 0  // forward/back tilt
//
//    init() {
//        // Check if the device has a gyroscope
//        guard manager.isDeviceMotionAvailable else { return }
//
//        manager.deviceMotionUpdateInterval = 1 / 60  // 60 times per second
//        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
//            guard let motion else { return }
//            // gravity gives us tilt — clamp to a small range so it's subtle
//            self?.tiltX = CGFloat(motion.gravity.x).clamped(to: -0.3...0.3)
//            self?.tiltY = CGFloat(motion.gravity.y).clamped(to: -0.3...0.3)
//        }
//    }
//
//    deinit { manager.stopDeviceMotionUpdates() }
//}
//
//// Helper so we can clamp values easily
//extension Comparable {
//    func clamped(to range: ClosedRange<Self>) -> Self {
//        min(max(self, range.lowerBound), range.upperBound)
//    }
//}

//Peaceful Mascot (unchanged)



private struct Particle {
    let x: CGFloat; let y: CGFloat; let size: CGFloat
    let color: Color; let duration: Double; let delay: Double
}




private let mascotParticles: [Particle] = [
    Particle(x: -38, y: -32, size: 3,   color: Color.rAccent.opacity(0.65), duration: 2.2, delay: 0.0),
    Particle(x:  36, y: -26, size: 2.5, color: Color.rGold.opacity(0.55),   duration: 2.8, delay: 0.4),
    Particle(x: -28, y:  20, size: 2,   color: Color.rTeal.opacity(0.55),   duration: 3.0, delay: 0.8),
    Particle(x:  32, y:  14, size: 3,   color: Color.rAccent.opacity(0.45), duration: 2.4, delay: 1.2),
    Particle(x:  -8, y: -46, size: 2,   color: Color.rGold.opacity(0.65),   duration: 2.6, delay: 0.6),
]

private func drawPeacefulEye(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, w: CGFloat) {
    var path = Path()
    path.move(to: CGPoint(x: cx - w / 2, y: cy))
    path.addQuadCurve(to: CGPoint(x: cx + w / 2, y: cy),
                      control: CGPoint(x: cx, y: cy - w * 0.45))
    ctx.stroke(path, with: .color(.white.opacity(0.85)), lineWidth: 1.8)
}

private func drawGentleSmile(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, w: CGFloat) {
    var path = Path()
    path.move(to: CGPoint(x: cx - w / 2, y: cy))
    path.addQuadCurve(to: CGPoint(x: cx + w / 2, y: cy),
                      control: CGPoint(x: cx, y: cy + w * 0.55))
    ctx.stroke(path, with: .color(.white.opacity(0.75)), lineWidth: 1.8)
}

struct PeacefulMascot: View {
    @State private var floating  = false
    @State private var pulsing   = false
    @State private var hueShift: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color.rViolet.opacity(0.45), Color.rTealDark.opacity(0.2), Color.clear],
                    center: .center, startRadius: 5, endRadius: 70))
                .frame(width: 140, height: 140)
                .blur(radius: 28)
                .scaleEffect(pulsing ? 1.2 : 0.85)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: pulsing)

            ForEach(mascotParticles.indices, id: \.self) { i in
                let p = mascotParticles[i]
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: floating ? p.y - 5 : p.y + 3)
                    .opacity(pulsing ? 0.9 : 0.2)
                    .animation(
                        .easeInOut(duration: p.duration).repeatForever(autoreverses: true).delay(p.delay),
                        value: pulsing)
            }

            VStack(spacing: 0) {
                Text("✦")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.rGold.opacity(0.9))
                    .offset(y: 5)

                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.rAccent.opacity(0.95), Color.rViolet.opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.rAccent.opacity(0.4), radius: 14)

                    Canvas { ctx, size in
                        let cx = size.width / 2
                        let cy = size.height / 2
                        drawPeacefulEye(ctx, cx: cx - 10, cy: cy - 2, w: 9)
                        drawPeacefulEye(ctx, cx: cx + 10, cy: cy - 2, w: 9)
                        drawGentleSmile(ctx, cx: cx, cy: cy + 8, w: 13)
                    }
                    .frame(width: 54, height: 54)
                }

                ZStack {
                    Capsule()
                        .fill(Color.rAccent.opacity(0.72))
                        .frame(width: 10, height: 12)
                        .offset(y: -18)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [Color.rViolet.opacity(0.80), Color.rTealDark.opacity(0.60)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: 32, height: 26)
                        .offset(y: -2)

                    Capsule()
                        .fill(Color.rAccent.opacity(0.65))
                        .frame(width: 40, height: 9)
                        .rotationEffect(.degrees(18))
                        .offset(x: -32, y: 6)

                    Capsule()
                        .fill(Color.rAccent.opacity(0.65))
                        .frame(width: 40, height: 9)
                        .rotationEffect(.degrees(-18))
                        .offset(x: 32, y: 6)

                    Circle()
                        .fill(Color.rAccent.opacity(0.80))
                        .frame(width: 11, height: 11)
                        .offset(x: -52, y: 14)

                    Circle()
                        .fill(Color.rAccent.opacity(0.80))
                        .frame(width: 11, height: 11)
                        .offset(x: 52, y: 14)

                    Ellipse()
                        .fill(LinearGradient(
                            colors: [Color.rViolet.opacity(0.58), Color.rTealDark.opacity(0.48)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: 62, height: 20)
                        .offset(y: 18)

                    Ellipse()
                        .fill(Color.rAccent.opacity(0.52))
                        .frame(width: 14, height: 8)
                        .offset(x: 27, y: 24)

                    Ellipse()
                        .fill(Color.rAccent.opacity(0.52))
                        .frame(width: 14, height: 8)
                        .offset(x: -27, y: 24)
                }
                .frame(width: 130, height: 52)
                .offset(y: -2)
            }
        }
        .hueRotation(.degrees(hueShift))
        .frame(width: 175, height: 155)
        .offset(y: floating ? -7 : 5)
        .animation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true), value: floating)
        .onAppear {
            floating = true
            pulsing  = true
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { hueShift = 20 }
        }
    }
}

//Mood Face Drawing 

private func drawMoodFace(ctx: GraphicsContext, size: CGSize, mood: Mood) {
    let w  = size.width, h = size.height
    let cx = w / 2,     cy = h / 2
    let eyeY   = cy - h * 0.07
    let mouthY = cy + h * 0.12
    let es     = w * 0.16
    let ew     = w * 0.13
    let color  = mood.color.opacity(0.9)
    let lw: CGFloat = 2.0

    switch mood {
    case .joyful:
        for side: CGFloat in [-1, 1] {
            var p = Path()
            p.move(to:    CGPoint(x: cx + side * es - ew, y: eyeY))
            p.addQuadCurve(to: CGPoint(x: cx + side * es + ew, y: eyeY),
                           control: CGPoint(x: cx + side * es, y: eyeY - ew * 0.9))
            ctx.stroke(p, with: .color(color), lineWidth: lw)
        }
        var m = Path()
        m.move(to: CGPoint(x: cx - w * 0.30, y: mouthY))
        m.addQuadCurve(to: CGPoint(x: cx + w * 0.30, y: mouthY),
                       control: CGPoint(x: cx, y: mouthY + h * 0.15))
        ctx.stroke(m, with: .color(color), lineWidth: lw)

    case .peaceful:
        for side: CGFloat in [-1, 1] {
            var p = Path()
            p.move(to:    CGPoint(x: cx + side * es - ew, y: eyeY))
            p.addQuadCurve(to: CGPoint(x: cx + side * es + ew, y: eyeY),
                           control: CGPoint(x: cx + side * es, y: eyeY - ew * 0.6))
            ctx.stroke(p, with: .color(color), lineWidth: lw)
        }
        var m = Path()
        m.move(to: CGPoint(x: cx - w * 0.20, y: mouthY))
        m.addQuadCurve(to: CGPoint(x: cx + w * 0.20, y: mouthY),
                       control: CGPoint(x: cx, y: mouthY + h * 0.09))
        ctx.stroke(m, with: .color(color), lineWidth: lw)

    case .neutral:
        for side: CGFloat in [-1, 1] {
            let r = ew * 0.6
            ctx.fill(Path(ellipseIn: CGRect(x: cx + side * es - r, y: eyeY - r, width: r*2, height: r*2)),
                     with: .color(color))
        }
        var m = Path()
        m.move(to: CGPoint(x: cx - w * 0.20, y: mouthY))
        m.addLine(to: CGPoint(x: cx + w * 0.20, y: mouthY))
        ctx.stroke(m, with: .color(color), lineWidth: lw)

    case .overwhelmed:
        for side: CGFloat in [-1, 1] {
            let r = ew * 0.85
            let rect = CGRect(x: cx + side * es - r, y: eyeY - r, width: r*2, height: r*2)
            ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1.5)
            ctx.fill(Path(ellipseIn: rect.insetBy(dx: 2.5, dy: 2.5)), with: .color(color))
        }
        var m = Path()
        let mw = w * 0.28
        m.move(to: CGPoint(x: cx - mw, y: mouthY))
        m.addCurve(to: CGPoint(x: cx + mw, y: mouthY),
                   control1: CGPoint(x: cx - mw * 0.4, y: mouthY - h * 0.04),
                   control2: CGPoint(x: cx + mw * 0.4, y: mouthY + h * 0.04))
        ctx.stroke(m, with: .color(color), lineWidth: lw)

    case .frustrated:
        for side: CGFloat in [-1, 1] {
            var brow = Path()
            brow.move(to: CGPoint(x: cx + side * es * 0.4, y: eyeY - ew * 1.1))
            brow.addLine(to: CGPoint(x: cx + side * (es + ew * 0.8), y: eyeY - ew * 0.5))
            ctx.stroke(brow, with: .color(color), lineWidth: 1.8)
            let r = ew * 0.55
            ctx.fill(Path(ellipseIn: CGRect(x: cx + side * es - r, y: eyeY - r * 0.5, width: r*2, height: r*2)),
                     with: .color(color))
        }
        var m = Path()
        m.move(to: CGPoint(x: cx - w * 0.20, y: mouthY + h * 0.03))
        m.addQuadCurve(to: CGPoint(x: cx + w * 0.20, y: mouthY + h * 0.03),
                       control: CGPoint(x: cx, y: mouthY - h * 0.05))
        ctx.stroke(m, with: .color(color), lineWidth: lw)

    case .heavy:
        for side: CGFloat in [-1, 1] {
            let r = ew * 0.65
            ctx.fill(Path(ellipseIn: CGRect(x: cx + side * es - r, y: eyeY - r * 0.8,
                                            width: r*2, height: r*1.6)),
                     with: .color(color.opacity(0.5)))
            var lid = Path()
            lid.move(to:  CGPoint(x: cx + side * es - r - 1, y: eyeY - r * 0.2))
            lid.addLine(to: CGPoint(x: cx + side * es + r + 1, y: eyeY - r * 0.2))
            ctx.stroke(lid, with: .color(color), lineWidth: 1.8)
        }
        var m = Path()
        m.move(to: CGPoint(x: cx - w * 0.18, y: mouthY + h * 0.02))
        m.addQuadCurve(to: CGPoint(x: cx + w * 0.18, y: mouthY + h * 0.02),
                       control: CGPoint(x: cx, y: mouthY - h * 0.06))
        ctx.stroke(m, with: .color(color), lineWidth: lw)
    }
}

// Mood Face View

struct MoodFaceView: View {
    let mood: Mood
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(mood.color.opacity(isSelected ? 0.25 : 0.08))
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: size * 0.25)

            // Main sphere with gradient for 3D depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            mood.color.opacity(isSelected ? 0.45 : 0.20),
                            mood.color.opacity(isSelected ? 0.25 : 0.10),
                            mood.color.opacity(0.03)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.30),
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .overlay(
                    // Inner highlight for glassy depth
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(isSelected ? 0.20 : 0.08),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.35, y: 0.25),
                                startRadius: 0,
                                endRadius: size * 0.35
                            )
                        )
                )
                .overlay(
                    // Rim light
                    Circle().stroke(
                        LinearGradient(
                            colors: [
                                mood.color.opacity(isSelected ? 0.7 : 0.3),
                                mood.color.opacity(isSelected ? 0.2 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
                )
                // Drop shadow for lift
                .shadow(color: Color.black.opacity(0.4), radius: size * 0.08, x: 0, y: size * 0.04)
                // Colored glow when selected
                .shadow(color: isSelected ? mood.color.opacity(0.5) : .clear, radius: size * 0.2)

            Canvas { ctx, sz in drawMoodFace(ctx: ctx, size: sz, mood: mood) }
        }
        .frame(width: size, height: size)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

//Floating Yoga Pose//

struct FloatingYogaPose: View {
    @State private var floating = false

    var body: some View {
        Image("YogaPose")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .shadow(color: Color.rAccent.opacity(0.3), radius: 20)
            .offset(y: floating ? -8 : 8)
            .animation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: floating
            )
            .onAppear { floating = true }
    }
}

//Mood Carousel (shared between both views)

private struct MoodCarousel: View {
    let moods: [Mood]
    @Binding var selectedIndex: Int
    var onSelect: (Mood) -> Void

    // Carousel geometry
    private let cardSpacing: CGFloat = 140
    private let selectedSize: CGFloat = 140
    private let deselectedSize: CGFloat = 64

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ZStack {
                ForEach(Array(moods.enumerated()), id: \.element) { index, mood in
                    let offset = CGFloat(index - selectedIndex) * cardSpacing
                    let distance = abs(CGFloat(index - selectedIndex))
                    let scale = max(0.4, 1.0 - distance * 0.35)
                    let opacity = max(0.15, 1.0 - distance * 0.45)
                    let size = distance < 0.5 ? selectedSize : deselectedSize
                    let isCenter = index == selectedIndex

//Adjust the wording under the Mood Faces
                    VStack(spacing: 28) {
                        MoodFaceView(mood: mood, isSelected: isCenter, size: size)

                        if isCenter {
                            Text(mood.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(mood.color)
                                .tracking(0.4)
                                .transition(.opacity)
                        }
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .offset(x: offset)
                    .zIndex(isCenter ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedIndex)
                }
            }
            .frame(width: geo.size.width, height: selectedSize + 40)
            .position(x: centerX, y: geo.size.height / 2)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 40
                        if value.translation.width < -threshold, selectedIndex < moods.count - 1 {
                            selectedIndex += 1
                        } else if value.translation.width > threshold, selectedIndex > 0 {
                            selectedIndex -= 1
                        }
                    }
            )
            .onTapGesture { location in
                // Tap left/right of center to navigate
                if location.x < centerX - 30, selectedIndex > 0 {
                    selectedIndex -= 1
                } else if location.x > centerX + 30, selectedIndex < moods.count - 1 {
                    selectedIndex += 1
                } else {
                    // Tap center to confirm
                    onSelect(moods[selectedIndex])
                }
            }
            .sensoryFeedback(.selection, trigger: selectedIndex)
        }
        .frame(height: selectedSize + 50)
    }
}

//Balloon Pop Burst

private struct BalloonPopBurst: View {
    let color: Color
    @State private var animate = false

    private let particleCount = 12

    var body: some View {
        ZStack {
            // Central flash
            Circle()
                .fill(color.opacity(animate ? 0 : 0.8))
                .frame(width: animate ? 200 : 40, height: animate ? 200 : 40)
                .blur(radius: animate ? 30 : 5)

            // Scatter particles
            ForEach(0..<particleCount, id: \.self) { i in
                let angle = Double(i) / Double(particleCount) * .pi * 2
                let distance: CGFloat = animate ? CGFloat.random(in: 100...180) : 0

                Circle()
                    .fill(color)
                    .frame(width: CGFloat.random(in: 6...14), height: CGFloat.random(in: 6...14))
                    .offset(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance
                    )
                    .opacity(animate ? 0 : 1)
                    .blur(radius: animate ? 4 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
    }
}

//Mood Selection View

struct MoodSelectionView: View {
    var onContinue: (Mood) -> Void

    private let moods = Mood.allCases
    private let positiveMoods = Mood.positiveMoods

    @State private var selectedIndex: Int = 0
    @State private var desiredIndex: Int = 0
    @State private var titleOpacity: Double = 0
    @State private var carouselOpacity: Double = 0

    // Pop flow states
    @State private var phase: SelectionPhase = .choosing
    @State private var popColor: Color = .clear
    @State private var popTrigger = 0

    private enum SelectionPhase {
        case choosing       // First carousel — "What is your peace?"
        case popping        // Pop animation playing
        case desiredMood    // Second carousel — "What do you want to feel?"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 45/255, green: 20/255, blue: 80/255),
                    Color(red: 25/255, green: 10/255, blue: 50/255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            StarsBackground()
                .ignoresSafeArea()

            ambientOrbs
                .opacity(0.5)

            switch phase {
            case .choosing:
                VStack(spacing: 0) {
                    VStack(spacing: 15) {
                        Text("What is Your")
                            .font(.custom("Georgia", size: 28))
                            .foregroundStyle(Color.rText)
                        Text("PEACE?")
                            .font(.custom("Georgia", size: 28))
                            .foregroundStyle(Color.rAccent)
                    }
                    .opacity(titleOpacity)
                    .padding(.top, 60)

                    Spacer()

                    MoodCarousel(
                        moods: moods,
                        selectedIndex: $selectedIndex
                    ) { mood in
                        handleMoodSelected(mood)
                    }
                    .opacity(carouselOpacity)

                    FloatingYogaPose()
                        .opacity(carouselOpacity)
                        .padding(.top, 20)

                    Spacer()
                }
                .transition(.opacity)

            case .popping:
                BalloonPopBurst(color: popColor)
                    .transition(.opacity)

            case .desiredMood:
                VStack(spacing: 0) {
                    VStack(spacing: 15) {
                        Text("What do you")
                            .font(.custom("Georgia", size: 50))
                            .foregroundStyle(Color.rText)
                        Text("want to feel?")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.rAccent)
                    }
                    .padding(.top, 60)

                    Spacer()

                    MoodCarousel(
                        moods: positiveMoods,
                        selectedIndex: $desiredIndex
                    ) { mood in
                        onContinue(mood)
                    }

                    FloatingYogaPose()
                        .padding(.top, 20)

                    Spacer()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: popTrigger)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) { titleOpacity = 1 }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) { carouselOpacity = 1 }
        }
    }

    private func handleMoodSelected(_ mood: Mood) {
        if mood.isNegative {
            // Pop the balloon, then show desired mood carousel
            popColor = mood.color
            popTrigger += 1

            withAnimation(.easeOut(duration: 0.3)) {
                phase = .popping
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                desiredIndex = 0
                withAnimation(.easeInOut(duration: 0.5)) {
                    phase = .desiredMood
                }
            }
        } else {
            // Positive mood — go straight through
            onContinue(mood)
        }
    }

    
    
    
    private var ambientOrbs: some View {
        ZStack {
            Circle().fill(Color.rViolet).frame(width: 350, height: 350)
                .blur(radius: 130).opacity(0.25).offset(x: -80, y: -200)
            Circle().fill(Color.rTealDark).frame(width: 300, height: 300)
                .blur(radius: 130).opacity(0.20).offset(x: 80, y: 200)
        }
        .ignoresSafeArea()
    }
}

// Post-Breathing Check-in

struct PostBreathingCheckinView: View {
    var onContinue: (Mood) -> Void

    private let moods = Mood.allCases
    @State private var selectedIndex: Int = 0
    @State private var titleOpacity: Double = 0
    @State private var carouselOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 45/255, green: 20/255, blue: 80/255),
                    Color(red: 25/255, green: 10/255, blue: 50/255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            checkinAmbientOrbs
                .opacity(0.5)

            VStack(spacing: 0) {

                VStack(spacing: 12) {
                    Text("How are you")
                        .font(.custom("Georgia", size: 28))
                        .foregroundStyle(Color.rText)
                    Text("feeling now?")
                        .font(.custom("Georgia", size: 28))
                        .foregroundStyle(Color.rAccent)
                }
                .opacity(titleOpacity)
                .padding(.top, 60)

                Spacer()

                MoodCarousel(
                    moods: moods,
                    selectedIndex: $selectedIndex
                ) { mood in
                    onContinue(mood)
                }
                .opacity(carouselOpacity)

                FloatingYogaPose()
                    .opacity(carouselOpacity)
                    .padding(.top, 20)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) { titleOpacity = 1 }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) { carouselOpacity = 1 }
        }
    }


    
    private var checkinAmbientOrbs: some View {
        ZStack {
            Circle().fill(Color.rViolet).frame(width: 350, height: 350)
                .blur(radius: 130).opacity(0.25).offset(x: -80, y: -200)
            Circle().fill(Color.rTealDark).frame(width: 300, height: 300)
                .blur(radius: 130).opacity(0.20).offset(x: 80, y: 200)
        }
        .ignoresSafeArea()
    }
}




#Preview("Check-in") {
    PostBreathingCheckinView { _ in }
}

#Preview {
    MoodSelectionView { _ in }
}
