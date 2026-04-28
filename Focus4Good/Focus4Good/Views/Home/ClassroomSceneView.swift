import SwiftUI

// MARK: - ClassroomSceneView

/// A 2D layered classroom with drag-and-drop support.
/// Users can drag items to reposition them. Positions persist via ClassroomStore.
struct ClassroomSceneView: View {

    let unlockedItems: [ClassroomItem]
    var selectedItemID: Binding<String?>?
    let classroomStore: ClassroomStore
    var isEditMode: Bool = false

    // Canvas reference — square canvas, scales to fill screen width
    private let canvasSize: CGFloat = 400

    // Ambient animation states
    @State private var sunlightPhase: Double = 0
    @State private var dustParticles: [DustParticle] = DustParticle.generate(10)
    @State private var ambientTimer: Timer?

    var body: some View {
        GeometryReader { geo in
            // Scale to fill screen width
            let scale = geo.size.width / canvasSize

            ZStack {
                // ─── Layer 1: Background Color ───
                Color(red: 0.96, green: 0.94, blue: 0.90)

                // ─── Layer 2: Classroom Scene (scaled canvas) ───
                ZStack {
                    Image("classroom_bg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: canvasSize, height: canvasSize)

                    // ─── Layer 3: Warm Mood Overlay ───
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.05 + sunlightPhase * 0.02),
                                    Color.clear
                                ],
                                center: .topTrailing,
                                startRadius: 20,
                                endRadius: 350
                            )
                        )
                        .frame(width: canvasSize, height: canvasSize)
                        .allowsHitTesting(false)

                    // ─── Layer 4: Item Sprites (draggable) ───
                    ForEach(unlockedItems) { item in
                        if let config = itemConfig(for: item.id) {
                            DraggableSpriteWrapper(
                                item: item,
                                config: config,
                                scale: scale,
                                isSelected: selectedItemID?.wrappedValue == item.id,
                                isEditMode: isEditMode,
                                classroomStore: classroomStore,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        if selectedItemID?.wrappedValue == item.id {
                                            selectedItemID?.wrappedValue = nil
                                        } else {
                                            selectedItemID?.wrappedValue = item.id
                                        }
                                    }
                                }
                            )
                            .zIndex(config.zIndex)
                        }
                    }

                    // ─── Layer 5: Floating Dust Particles ───
                    ForEach(dustParticles) { particle in
                        Circle()
                            .fill(Color.white.opacity(particle.opacity))
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .blur(radius: 0.5)
                    }
                    .allowsHitTesting(false)

                    // ─── Edit Mode Grid Overlay ───
                    if isEditMode {
                        RoundedRectangle(cornerRadius: 0)
                            .strokeBorder(AppTheme.orange.opacity(0.15), lineWidth: 0.5)
                            .frame(width: canvasSize, height: canvasSize)
                            .allowsHitTesting(false)
                    }
                }
                .scaleEffect(scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: unlockedItems.count)
        .onAppear { startAmbientAnimations() }
        .onDisappear { stopAmbientAnimations() }
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            sunlightPhase = 1.0
        }
        ambientTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            DispatchQueue.main.async {
                for i in dustParticles.indices {
                    dustParticles[i].y -= dustParticles[i].speed
                    dustParticles[i].x += sin(dustParticles[i].y * 0.02) * 0.3
                    dustParticles[i].opacity = max(0, min(0.35, dustParticles[i].opacity + Double.random(in: -0.02...0.02)))
                    if dustParticles[i].y < -250 {
                        dustParticles[i].y = 250
                        dustParticles[i].x = CGFloat.random(in: -200...200)
                        dustParticles[i].opacity = Double.random(in: 0.1...0.25)
                    }
                }
            }
        }
    }

    private func stopAmbientAnimations() {
        ambientTimer?.invalidate()
        ambientTimer = nil
    }

    // MARK: - Item Placement Config

    func itemConfig(for id: String) -> SpriteConfig? {
        switch id {
        case "classroom":
            return nil

        // ─── WALL ITEMS ───

        case "chalkboard":
            return SpriteConfig(
                imageName: "item_chalkboard",
                x: 40, y: -95,
                width: 65, height: 52,
                zIndex: 1,
                isWallItem: true,
                defaultRotation: 5,
                ambientAnimation: .none
            )

        case "clock":
            return SpriteConfig(
                imageName: "item_clock",
                x: -132, y: -68,
                width: 34, height: 34,
                zIndex: 1,
                isWallItem: true,
                ambientAnimation: .pendulum
            )

        case "world_map":
            return SpriteConfig(
                imageName: "item_worldmap",
                x: -22, y: -98,
                width: 50, height: 38,
                zIndex: 1,
                isWallItem: true,
                defaultRotation: 5,
                ambientAnimation: .none
            )

        // ─── FLOOR ITEMS ───

        case "teacher_desk":
            return SpriteConfig(
                imageName: "item_teacherdesk",
                x: 35, y: -15,
                width: 80, height: 62,
                zIndex: 3,
                ambientAnimation: .none
            )

        case "student_desk":
            return SpriteConfig(
                imageName: "item_desk",
                x: -25, y: 45,
                width: 72, height: 60,
                zIndex: 5,
                ambientAnimation: .none
            )

        case "bookshelf":
            return SpriteConfig(
                imageName: "item_bookshelf",
                x: 105, y: -10,
                width: 60, height: 56,
                zIndex: 2,
                ambientAnimation: .none
            )

        case "pencil_holder":
            return SpriteConfig(
                imageName: "item_pencilholder",
                x: 0, y: 32,
                width: 26, height: 30,
                zIndex: 6,
                ambientAnimation: .none
            )

        case "globe":
            return SpriteConfig(
                imageName: "item_globe",
                x: 95, y: 55,
                width: 40, height: 46,
                zIndex: 4,
                ambientAnimation: .none
            )

        case "plant":
            return SpriteConfig(
                imageName: "item_plant",
                x: -105, y: 60,
                width: 45, height: 52,
                zIndex: 7,
                ambientAnimation: .sway
            )

        case "backpack":
            return SpriteConfig(
                imageName: "item_backpack",
                x: -60, y: 72,
                width: 36, height: 40,
                zIndex: 6,
                ambientAnimation: .none
            )

        case "student":
            return SpriteConfig(
                imageName: "item_student",
                x: -65, y: 22,
                width: 38, height: 58,
                zIndex: 5,
                ambientAnimation: .breathe
            )

        case "desk_extra":
            // Front-right area of the floor
            return SpriteConfig(
                imageName: "item_desk_empty2",
                x: 55, y: 75,
                width: 68, height: 56,
                zIndex: 6,
                ambientAnimation: .none
            )

        case "desk_boy":
            // Middle-left area
            return SpriteConfig(
                imageName: "item_desk_boy",
                x: -90, y: 0,
                width: 65, height: 75,
                zIndex: 4,
                ambientAnimation: .breathe
            )

        case "desk_girl":
            // Middle-right area
            return SpriteConfig(
                imageName: "item_desk_girl",
                x: 20, y: 85,
                width: 65, height: 75,
                zIndex: 7,
                ambientAnimation: .breathe
            )

        default:
            return nil
        }
    }
}


// MARK: - Draggable Sprite Wrapper

/// Wraps a ClassroomSpriteView with drag gesture support.
/// Uses custom positions from ClassroomStore if available, otherwise defaults.
struct DraggableSpriteWrapper: View {
    let item: ClassroomItem
    let config: SpriteConfig
    let scale: CGFloat
    var isSelected: Bool
    var isEditMode: Bool
    let classroomStore: ClassroomStore
    var onTap: (() -> Void)?

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var rotationDelta: Double = 0

    /// The item's current position (custom if set, otherwise default from config)
    private var currentX: CGFloat {
        if let custom = classroomStore.customPosition(for: item.id) {
            return custom.x
        }
        return config.x
    }

    private var currentY: CGFloat {
        if let custom = classroomStore.customPosition(for: item.id) {
            return custom.y
        }
        return config.y
    }

    /// The item's current rotation (from store)
    private var currentRotation: Double {
        config.defaultRotation + classroomStore.customRotation(for: item.id)
    }

    var body: some View {
        ClassroomSpriteView(
            item: item,
            config: config,
            isSelected: isSelected,
            isDragging: isDragging,
            isEditMode: isEditMode,
            onTap: onTap,
            onRotate: { delta in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    let newRotation = currentRotation + delta
                    classroomStore.setCustomRotation(for: item.id, degrees: newRotation)
                }
            }
        )
        .rotationEffect(.degrees(currentRotation + rotationDelta))
        .offset(
            x: currentX + dragOffset.width / scale,
            y: currentY + dragOffset.height / scale
        )
        .gesture(isEditMode ? dragGesture : nil)
        .simultaneousGesture(isEditMode ? rotationGesture : nil)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                let finalX = currentX + value.translation.width / scale
                let finalY = currentY + value.translation.height / scale
                classroomStore.setCustomPosition(for: item.id, x: finalX, y: finalY)
                dragOffset = .zero
            }
    }

    // MARK: - Rotation Gesture

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                isDragging = true
                rotationDelta = angle.degrees
            }
            .onEnded { angle in
                isDragging = false
                let finalRotation = currentRotation + angle.degrees
                classroomStore.setCustomRotation(for: item.id, degrees: finalRotation)
                rotationDelta = 0
            }
    }
}


// MARK: - Ambient Animation Type

enum AmbientAnimation {
    case none
    case pendulum
    case sway
    case spin
    case breathe
}

// MARK: - Sprite Config

struct SpriteConfig {
    let imageName: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let zIndex: Double
    var isWallItem: Bool = false
    var defaultRotation: Double = 0  // degrees, to match wall perspective
    var ambientAnimation: AmbientAnimation = .none
}

// MARK: - Dust Particle

struct DustParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat

    static func generate(_ count: Int) -> [DustParticle] {
        (0..<count).map { _ in
            DustParticle(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -200...200),
                size: CGFloat.random(in: 2...4),
                opacity: Double.random(in: 0.08...0.2),
                speed: CGFloat.random(in: 0.15...0.4)
            )
        }
    }
}


// MARK: - Individual Sprite View

struct ClassroomSpriteView: View {
    let item: ClassroomItem
    let config: SpriteConfig
    var isSelected: Bool = false
    var isDragging: Bool = false
    var isEditMode: Bool = false
    var onTap: (() -> Void)?
    var onRotate: ((Double) -> Void)?

    @State private var appeared = false
    @State private var isBouncing = false

    // Ambient animation states
    @State private var pendulumAngle: Double = 0
    @State private var swayOffset: CGFloat = 0
    @State private var spinAngle: Double = 0
    @State private var breatheScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Image(config.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: config.width, height: config.height)
                    .modifier(AmbientAnimationModifier(
                        animation: config.ambientAnimation,
                        pendulumAngle: pendulumAngle,
                        swayOffset: swayOffset,
                        spinAngle: spinAngle,
                        breatheScale: breatheScale
                    ))

                // Selection / drag highlight
                if isSelected || isDragging {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isDragging ? Color.blue : AppTheme.orange,
                            style: StrokeStyle(
                                lineWidth: isDragging ? 2 : 1.5,
                                dash: isDragging ? [6, 3] : []
                            )
                        )
                        .frame(width: config.width + 6, height: config.height + 6)
                        .shadow(color: (isDragging ? Color.blue : AppTheme.orange).opacity(0.3), radius: 6)
                }

                // Edit mode controls (rotate + move)
                if isEditMode && !isDragging {
                    HStack(spacing: 4) {
                        // Rotate left button
                        Button {
                            onRotate?(-5)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.blue))
                        }

                        // Move indicator
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(AppTheme.orange))

                        // Rotate right button
                        Button {
                            onRotate?(5)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.blue))
                        }
                    }
                    .offset(y: -14)
                }
            }

            // Shadow under floor items
            if !config.isWallItem {
                Ellipse()
                    .fill(Color.black.opacity(isDragging ? 0.15 : 0.08))
                    .frame(width: config.width * 0.6, height: isDragging ? 8 : 5)
                    .offset(y: -2)
            }

            // Tooltip (only in non-edit mode)
            if isSelected && !isEditMode {
                tooltipView
                    .transition(.scale(scale: 0.5, anchor: .top).combined(with: .opacity))
            }
        }
        .scaleEffect(appeared ? (isDragging ? 1.12 : (isBouncing ? 1.08 : 1.0)) : 0.0)
        .opacity(appeared ? (isDragging ? 0.85 : 1.0) : 0.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.55)
                .delay(entranceDelay)
            ) {
                appeared = true
            }
            startAmbientAnimation()
        }
        .onTapGesture {
            guard !isEditMode else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                isBouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    isBouncing = false
                }
            }
            onTap?()
        }
    }

    private var tooltipView: some View {
        VStack(spacing: 2) {
            Text(item.emoji)
                .font(.system(size: 14))
            Text(item.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.75))
        )
        .offset(y: 4)
    }

    private var entranceDelay: Double {
        config.zIndex * 0.08 + Double.random(in: 0...0.1)
    }

    private func startAmbientAnimation() {
        switch config.ambientAnimation {
        case .pendulum:
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pendulumAngle = 3
            }
        case .sway:
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                swayOffset = 2
            }
        case .spin:
            withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        case .breathe:
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breatheScale = 1.03
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                swayOffset = -3  // gentle bob up
            }
        case .none:
            break
        }
    }
}

// MARK: - Ambient Animation Modifier

struct AmbientAnimationModifier: ViewModifier {
    let animation: AmbientAnimation
    let pendulumAngle: Double
    let swayOffset: CGFloat
    let spinAngle: Double
    let breatheScale: CGFloat

    func body(content: Content) -> some View {
        switch animation {
        case .pendulum:
            content.rotationEffect(.degrees(pendulumAngle), anchor: .top)
        case .sway:
            content.offset(x: swayOffset)
        case .spin:
            content.rotation3DEffect(.degrees(spinAngle), axis: (x: 0, y: 1, z: 0))
        case .breathe:
            content
                .scaleEffect(breatheScale)
                .offset(y: swayOffset)
        case .none:
            content
        }
    }
}

// MARK: - Pulse Effect

struct ClassroomPulseEffect: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1.08 : 1.0)
            .shadow(color: AppTheme.orange.opacity(on ? 0.4 : 0.1), radius: on ? 12 : 4)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}
