import SwiftUI

// MARK: - Virtual Classroom View

/// Full-screen immersive view showing the 2D layered classroom and an item shop
/// where users spend Focus Points to unlock new items.
/// Enhanced with courtroom-style overlays, celebrations, and screen shake.
struct VirtualClassroomView: View {
    @Environment(ClassroomStore.self) private var classroomStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var showShop = false
    @State private var justUnlockedItem: ClassroomItem?
    @State private var showUnlockCelebration = false
    @State private var selectedItemID: String?

    // Celebration animation states
    @State private var celebrationScale: CGFloat = 3.0
    @State private var celebrationOpacity: Double = 0
    @State private var celebrationTextVisible = false
    @State private var sparkleRingScale: CGFloat = 0.2
    @State private var sparkleRingOpacity: Double = 0

    // Screen shake (courtroom technique)
    @State private var shake: CGFloat = 0

    // Shop button pulse
    @State private var canAffordSomething = false

    // Edit mode (drag to rearrange)
    @State private var isEditMode = false

    // Zoom & Pan
    @State private var currentZoom: CGFloat = 1.0
    @State private var gestureZoom: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var gesturePan: CGSize = .zero

    private var totalZoom: CGFloat {
        min(max(currentZoom * gestureZoom, 1.0), 3.0)
    }

    private var totalOffset: CGSize {
        CGSize(
            width: panOffset.width + gesturePan.width,
            height: panOffset.height + gesturePan.height
        )
    }

    var body: some View {
        ZStack {
            // MARK: - Classroom Scene (Full Screen, Zoomable)
            ClassroomSceneView(
                unlockedItems: classroomStore.unlockedItems,
                selectedItemID: $selectedItemID,
                classroomStore: classroomStore,
                isEditMode: isEditMode
            )
            .scaleEffect(totalZoom)
            .offset(totalOffset)
            .gesture(zoomGesture)
            .simultaneousGesture(totalZoom > 1.05 ? panGesture : nil)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentZoom = 1.0
                    gestureZoom = 1.0
                    panOffset = .zero
                    gesturePan = .zero
                }
            }
            .ignoresSafeArea()
            .offset(x: shake)

            // MARK: - Overlay UI
            VStack {
                topBar
                Spacer()

                // Floating Arrange button (bottom-right, above bottom bar)
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditMode.toggle()
                            if isEditMode { selectedItemID = nil }
                        }
                    } label: {
                        Image(systemName: isEditMode ? "checkmark" : "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isEditMode ? .white : AppTheme.orange)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle().fill(isEditMode ? AnyShapeStyle(AppTheme.orange) : AnyShapeStyle(.ultraThinMaterial))
                            )
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 8)

                bottomBar
            }
            .offset(x: shake)

            // MARK: - Unlock Celebration (Courtroom Evidence-Slam Style)
            if showUnlockCelebration, let item = justUnlockedItem {
                celebrationOverlay(for: item)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShop) {
            ShopView(
                classroomStore: classroomStore,
                userStore: userStore,
                onUnlock: { item in
                    justUnlockedItem = item
                    showShop = false
                    triggerUnlockCelebration()
                }
            )
        }
        .onAppear { checkAffordability() }
    }

    // MARK: - Zoom Gesture

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                gestureZoom = value
            }
            .onEnded { value in
                currentZoom = min(max(currentZoom * value, 1.0), 3.0)
                gestureZoom = 1.0
                // Reset pan if zoomed out to 1x
                if currentZoom <= 1.01 {
                    withAnimation(.spring(response: 0.3)) {
                        panOffset = .zero
                    }
                }
            }
    }

    // MARK: - Pan Gesture (when zoomed in)

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                gesturePan = value.translation
            }
            .onEnded { value in
                panOffset = CGSize(
                    width: panOffset.width + value.translation.width,
                    height: panOffset.height + value.translation.height
                )
                gesturePan = .zero
            }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }

            Spacer()

            // Focus Points badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.orange)
                Text("\(userStore.currentUser?.focusPoints ?? 0)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(.ultraThinMaterial))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if isEditMode {
                // Edit mode bottom bar
                HStack(spacing: 12) {
                    // Reset layout button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            classroomStore.resetAllPositions()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Layout")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(AppTheme.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .stroke(AppTheme.orange, lineWidth: 2)
                                .background(Capsule().fill(.ultraThinMaterial))
                        )
                    }

                    // Done button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditMode = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Done")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [AppTheme.orange, Color(hex: "F4845F")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, y: 4)
                    }
                }

                // Edit mode hint
                Text("Drag items to rearrange your classroom")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else {
                // Normal mode bottom bar
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(AppTheme.orange)
                    Text("\(classroomStore.unlockedItems.count)/\(classroomStore.items.count) Items")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(.ultraThinMaterial)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                Button {
                    showShop = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bag.fill")
                        Text("Item Shop")
                            .font(.headline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [AppTheme.orange, Color(hex: "F4845F")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                    .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 4)
                }
                .modifier(canAffordSomething ? AnyShopPulse(active: true) : AnyShopPulse(active: false))
                .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 20)
        .animation(.spring(response: 0.3), value: isEditMode)
    }

    // MARK: - Room Level Name

    private var roomLevelName: String {
        let count = classroomStore.unlockedItems.count
        switch count {
        case 0...1:  return "📦 EMPTY ROOM"
        case 2...3:  return "🌱 STARTER SPACE"
        case 4...6:  return "📖 STUDY NOOK"
        case 7...9:  return "🎓 SCHOLAR'S DEN"
        default:     return "⭐ DREAM CLASSROOM"
        }
    }

    // MARK: - Celebration Overlay (Courtroom Evidence-Slam Style)

    private func celebrationOverlay(for item: ClassroomItem) -> some View {
        ZStack {
            // Dark backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }

            VStack(spacing: 16) {
                // Sparkle ring (expanding)
                ZStack {
                    ForEach(0..<10, id: \.self) { i in
                        Text("✨")
                            .font(.title2)
                            .offset(
                                x: 60 * cos(Double(i) * .pi / 5),
                                y: 60 * sin(Double(i) * .pi / 5)
                            )
                    }
                }
                .scaleEffect(sparkleRingScale)
                .opacity(sparkleRingOpacity)

                // Item emoji flying in (evidence slam: scale 3.0 → 1.0)
                Text(item.emoji)
                    .font(.system(size: 70))
                    .scaleEffect(celebrationScale)
                    .opacity(celebrationOpacity)

                // "UNLOCKED!" text with gradient (like "NOT GUILTY")
                if celebrationTextVisible {
                    Text("UNLOCKED!")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.orange, Color(hex: "F4845F"), .yellow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.orange, radius: 20)
                        .shadow(color: .black, radius: 5)
                        .transition(.scale(scale: 2.5).combined(with: .opacity))

                    Text(item.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)

                    // Continue button (courtroom style)
                    Button {
                        dismissCelebration()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Awesome!")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.orange, Color(hex: "F4845F")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: AppTheme.orange.opacity(0.5), radius: 12)
                        )
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Celebration Trigger (Courtroom Verdict Style)

    private func triggerUnlockCelebration() {
        // Reset states
        celebrationScale = 3.0
        celebrationOpacity = 0
        celebrationTextVisible = false
        sparkleRingScale = 0.2
        sparkleRingOpacity = 0

        withAnimation(.easeOut(duration: 0.2)) {
            showUnlockCelebration = true
        }

        // Screen shake (courtroom technique)
        triggerShake()

        // Item slam in (evidence slam: 3.0 → 1.0)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            celebrationScale = 1.0
            celebrationOpacity = 1.0
        }

        // Sparkle ring expands
        withAnimation(.spring(response: 0.6, dampingFraction: 0.4).delay(0.2)) {
            sparkleRingScale = 1.0
            sparkleRingOpacity = 1.0
        }

        // Text reveals (like verdict text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                celebrationTextVisible = true
            }
        }

        // Second shake for impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            triggerShake()
        }

        checkAffordability()
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            showUnlockCelebration = false
            celebrationTextVisible = false
        }
    }

    // MARK: - Screen Shake (Courtroom Technique)

    private func triggerShake() {
        let offsets: [(CGFloat, Double)] = [
            (12.0, 0.0), (-12.0, 0.06), (8.0, 0.12),
            (-8.0, 0.18), (4.0, 0.24), (0.0, 0.30)
        ]
        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.06, dampingFraction: 0.3)) {
                    shake = offset
                }
            }
        }
    }

    // MARK: - Affordability Check

    private func checkAffordability() {
        canAffordSomething = classroomStore.lockedItems.contains { item in
            classroomStore.canAfford(item, userStore: userStore)
        }
    }
}

// MARK: - Shop Button Pulse Wrapper

struct AnyShopPulse: ViewModifier {
    let active: Bool
    @State private var pulseOn = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && pulseOn ? 1.04 : 1.0)
            .animation(
                active
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: pulseOn
            )
            .onAppear { if active { pulseOn = true } }
            .onChange(of: active) { _, newValue in
                pulseOn = newValue
            }
    }
}


// MARK: - Shop View

struct ShopView: View {
    let classroomStore: ClassroomStore
    let userStore: UserStore
    var onUnlock: (ClassroomItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ShopCategory = .all

    enum ShopCategory: String, CaseIterable {
        case all = "All"
        case locked = "Locked"
        case unlocked = "Unlocked"
    }

    private var filteredItems: [ClassroomItem] {
        switch selectedCategory {
        case .all:
            return classroomStore.items.filter { $0.cost > 0 } // Exclude base classroom
        case .locked:
            return classroomStore.lockedItems
        case .unlocked:
            return classroomStore.unlockedItems.filter { $0.cost > 0 }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Points balance header
                pointsHeader

                // Category picker
                categoryPicker

                // Items grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredItems) { item in
                            ShopItemCard(
                                item: item,
                                canAfford: classroomStore.canAfford(item, userStore: userStore),
                                onUnlock: {
                                    Task {
                                        let success = await classroomStore.unlockItem(id: item.id, userStore: userStore)
                                        if success {
                                            // Find updated item
                                            if let updated = classroomStore.items.first(where: { $0.id == item.id }) {
                                                onUnlock(updated)
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Item Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.orange)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Points Header

    private var pointsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.orange)
                    Text("\(userStore.currentUser?.focusPoints ?? 0)")
                        .font(.title2.bold())
                }
            }

            Spacer()

            // Progress ring
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: classroomStore.progress)
                        .stroke(AppTheme.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.6), value: classroomStore.progress)
                }
                .frame(width: 40, height: 40)

                Text("\(classroomStore.unlockedItems.count)/\(classroomStore.items.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(ShopCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    Text(category.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(selectedCategory == category ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selectedCategory == category ? AppTheme.orange : Color(.systemGray5))
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ClassroomItem
    let canAfford: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Item icon / visual
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        item.isUnlocked
                        ? Color.green.opacity(0.08)
                        : (canAfford ? AppTheme.orange.opacity(0.08) : Color(.systemGray6))
                    )
                    .frame(height: 100)

                if item.isUnlocked {
                    VStack(spacing: 4) {
                        Text(item.emoji)
                            .font(.system(size: 32))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                    }
                } else {
                    VStack(spacing: 4) {
                        Text(item.emoji)
                            .font(.system(size: 32))
                            .opacity(canAfford ? 1.0 : 0.4)
                        Image(systemName: itemIcon(for: item.id))
                            .font(.system(size: 18))
                            .foregroundStyle(canAfford ? AppTheme.orange : Color(.systemGray3))
                    }
                }
            }

            // Item info
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(item.description)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            // Action button or status
            if item.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                    Text("Unlocked")
                        .font(.caption.bold())
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.green.opacity(0.12)))
            } else {
                Button(action: onUnlock) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("\(item.cost)")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            canAfford
                            ? AppTheme.orange
                            : Color(.systemGray4)
                        )
                    )
                }
                .disabled(!canAfford)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    // Map item IDs to SF Symbol icons for the shop cards
    private func itemIcon(for id: String) -> String {
        switch id {
        case "teacher_desk":  return "tablecells.fill"
        case "chalkboard":    return "rectangle.landscape.rotate"
        case "student_desk":  return "desktopcomputer"
        case "bookshelf":     return "books.vertical.fill"
        case "pencil_holder": return "pencil.and.ruler.fill"
        case "clock":         return "clock.fill"
        case "globe":         return "globe.americas.fill"
        case "plant":         return "leaf.fill"
        case "backpack":      return "backpack.fill"
        case "world_map":     return "map.fill"
        case "student":       return "person.fill"
        case "desk_extra":    return "chair.fill"
        case "desk_boy":      return "person.and.background.dotted"
        case "desk_girl":     return "person.and.background.striped.horizontal"
        default:              return "cube.fill"
        }
    }
}
