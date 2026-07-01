import SwiftUI

// MARK: - Navigation Destinations

enum HomeDestination: Hashable {
    case schedule
    case ngoList
}

// MARK: - HomeView

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(TaskStore.self) private var taskStore
    @Environment(VolunteerStore.self) private var volunteerStore
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false
    @State private var appeared = false

    private var todayGoalProgress: Double {
        let today = Date()
        let todayTasks = taskStore.todaysTasks
        let total = todayTasks.count
        guard total > 0 else { return 0.65 }
        return Double(todayTasks.filter { taskStore.isTaskCompleted($0, on: today) }.count) / Double(total)
    }

    private var focusPoints: Int {
        userStore.currentUser?.focusPoints ?? 120
    }

    private var greetingEmoji: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "🌅"
        case 12..<17: return "☀️"
        default: return "🌙"
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                let hPad: CGFloat = 18
                let topPad: CGFloat = 6
                let spacing: CGFloat = 12
                let usable = geo.size.height - topPad - spacing * 2

                // Proportions matched to reference: planner ~35%, stats ~25%, ngo ~35%
                let plannerH = usable * 0.345
                let statsH   = usable * 0.265
                let ngoH     = usable * 0.345

                VStack(spacing: spacing) {
                    plannerCard(height: plannerH, width: geo.size.width - hPad * 2)
                    statsRow(height: statsH)
                    ngoConnectCard(height: ngoH, width: geo.size.width - hPad * 2)
                }
                .padding(.horizontal, hPad)
                .padding(.top, topPad)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        ZStack {
                            Circle()
                                .fill(AppTheme.orange.opacity(0.15))
                                .frame(width: 38, height: 38)
                            Image(systemName: "person.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .navigationDestination(for: HomeDestination.self) { dest in
                switch dest {
                case .schedule:  ScheduleView()
                case .ngoList:   NGOListView()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Planner Hero Card
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func plannerCard(height: CGFloat, width: CGFloat) -> some View {
        Button {
            navigationPath.append(HomeDestination.schedule)
        } label: {
            Image("plannercard")
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(HomeCardButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Stats Row
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func statsRow(height: CGFloat) -> some View {
        HStack(spacing: 12) {
            focusPointsCard(height: height)
            todaysGoalCard(height: height)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    // MARK: Focus Points

    @ViewBuilder
    private func focusPointsCard(height: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Header icon + title
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.orange.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.orange)
                    }
                    Text("Focus Points")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.label))
                }
                .padding(.top, 16)

                Spacer(minLength: 4)

                // Big value
                Text("\(focusPoints)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(.label))
                    .contentTransition(.numericText())

                // Wavy line accent
                WavyLine()
                    .stroke(AppTheme.orange, lineWidth: 1.8)
                    .frame(width: 22, height: 8)
                    .padding(.top, 2)

                Text("Keep going!")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.top, 3)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)

            // Botanical leaf decoration (bottom-right)
            LeafDecoration()
                .frame(width: 55, height: 70)
                .opacity(0.25)
                .padding(.trailing, 6)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: Today's Goal

    @ViewBuilder
    private func todaysGoalCard(height: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.orange.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "target")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.orange)
                    }
                    Text("Today's Goal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.label))
                }
                .padding(.top, 16)

                Spacer(minLength: 4)

                Text("\(Int(todayGoalProgress * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(.label))
                    .contentTransition(.numericText())

                WavyLine()
                    .stroke(AppTheme.orange, lineWidth: 1.8)
                    .frame(width: 22, height: 8)
                    .padding(.top, 2)

                Text("On track!")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.top, 3)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - NGO Connect Card
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func ngoConnectCard(height: CGFloat, width: CGFloat) -> some View {
        Button {
            navigationPath.append(HomeDestination.ngoList)
        } label: {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBackground))

                HStack(spacing: 0) {
                    // Left: NGO Image
                    Image("ngo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: width * 0.40, height: height)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 22,
                                bottomLeadingRadius: 22,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                        )

                    // Right: Text Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NGO Connect")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(.label))

                        Text("Every point you earn helps fund education.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        // Points display
                        HStack(spacing: 4) {
                            Text("\(focusPoints)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.orange)
                            Text("/ 10,000 points")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(.secondaryLabel))
                                .padding(.top, 2)
                        }

                        Spacer(minLength: 4)

                        // Bottom link
                        HStack(spacing: 4) {
                            Text("Help us reach more lives")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(.secondaryLabel))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.orange)
                        }
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 16)
                    .padding(.vertical, 14)
                    .frame(width: width * 0.60, alignment: .leading)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(HomeCardButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: - Leaf Decoration (Focus Points card)
// ═════════════════════════════════════════════════════════════════════

struct LeafDecoration: View {
    var body: some View {
        ZStack {
            // Main stem
            LeafStem()
                .stroke(AppTheme.orange.opacity(0.5), lineWidth: 1.5)
                .frame(width: 40, height: 60)

            // Leaves
            Ellipse()
                .fill(AppTheme.orange.opacity(0.2))
                .frame(width: 14, height: 24)
                .rotationEffect(.degrees(-30))
                .offset(x: -8, y: -10)

            Ellipse()
                .fill(AppTheme.orange.opacity(0.15))
                .frame(width: 12, height: 20)
                .rotationEffect(.degrees(25))
                .offset(x: 8, y: -18)

            Ellipse()
                .fill(AppTheme.orange.opacity(0.18))
                .frame(width: 10, height: 18)
                .rotationEffect(.degrees(-15))
                .offset(x: -4, y: 6)

            Ellipse()
                .fill(AppTheme.orange.opacity(0.12))
                .frame(width: 12, height: 20)
                .rotationEffect(.degrees(35))
                .offset(x: 10, y: 0)
        }
    }
}

struct LeafStem: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - 5, y: rect.minY + 10),
            control: CGPoint(x: rect.midX + 8, y: rect.midY)
        )
        return path
    }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: - Shared Shapes & Styles
// ═════════════════════════════════════════════════════════════════════

struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amp = rect.height * 0.4
        let wl  = rect.width / 2.5
        let mid = rect.midY
        path.move(to: CGPoint(x: 0, y: mid))
        var x: CGFloat = 0
        while x <= rect.width {
            let y = mid + sin(x / wl * .pi * 2) * amp
            path.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }
        return path
    }
}

struct HomeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
