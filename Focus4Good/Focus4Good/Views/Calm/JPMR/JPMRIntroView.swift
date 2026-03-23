//
//  JPMRIntroView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Intro Data

private struct IntroGroup: Identifiable {
    let id: Int
    let name: String
    let icon: String
}

private let introGroups: [IntroGroup] = [
    .init(id: 1,  name: "Feet",            icon: "figure.walk"),
    .init(id: 2,  name: "Calves",          icon: "figure.run"),
    .init(id: 3,  name: "Thighs",          icon: "figure.strengthtraining.traditional"),
    .init(id: 4,  name: "Hips & Buttocks", icon: "figure.cooldown"),
    .init(id: 5,  name: "Abdomen",         icon: "figure.core.training"),
    .init(id: 6,  name: "Chest",           icon: "lungs.fill"),
    .init(id: 7,  name: "Hands & Forearms",icon: "hand.raised.fill"),
    .init(id: 8,  name: "Upper Arms",      icon: "figure.arms.open"),
    .init(id: 9,  name: "Shoulders",       icon: "figure.stand"),
    .init(id: 10, name: "Neck",            icon: "person.crop.circle"),
    .init(id: 11, name: "Face",            icon: "face.smiling"),
]

// MARK: - Constants

private let accentOrange = Color("CalmOrange")

// MARK: - JPMRIntroView

@available(iOS 17.0, *)
struct JPMRIntroView: View {

    @State private var showSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                animatedHeaderSection
                preparationSection
                techniqueSection
                muscleGroupsSection
                benefitsSection
                beginSection
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: $showSession) {
            JPMRSessionView()
        }
        .navigationTitle("Unwind Body")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension JPMRIntroView {

    // MARK: Animated Header

    var animatedHeaderSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 52))
                .foregroundStyle(accentOrange)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(phase ? 1.08 : 1.0)
                        .opacity(phase ? 1.0 : 0.75)
                } animation: { _ in
                    .easeInOut(duration: 2.0)
                }

            Text("Progressive Muscle Relaxation")
                .font(.title2)
                .fontWeight(.bold)

            Text("Systematically tense and release each muscle group to melt away physical tension and quiet your mind.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: Before You Begin

    var preparationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Before You Begin")
                .font(.headline)

            VStack(spacing: 0) {
                prepTipRow(icon: "mappin.circle.fill",
                           text: "Find a quiet, comfortable place")
                Divider().padding(.leading, 52)
                prepTipRow(icon: "tshirt.fill",
                           text: "Wear loose, comfortable clothing")
                Divider().padding(.leading, 52)
                prepTipRow(icon: "clock.fill",
                           text: "Allow 15–20 minutes without interruption")
                Divider().padding(.leading, 52)
                prepTipRow(icon: "eye.slash.fill",
                           text: "Close your eyes and breathe deeply to settle in")
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        }
    }

    func prepTipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(accentOrange)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: The Technique

    var techniqueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The Technique")
                .font(.headline)

            VStack(spacing: 0) {
                stepRow(title: "Tense",
                        detail: "Inhale and tense the muscle firmly for 7 seconds",
                        icon: "bolt.circle.fill")
                Divider().padding(.leading, 60)
                stepRow(title: "Release",
                        detail: "Exhale and release the tension completely",
                        icon: "arrow.down.circle.fill")
                Divider().padding(.leading, 60)
                stepRow(title: "Rest",
                        detail: "Rest for 20 seconds, notice the warmth and relaxation",
                        icon: "moon.circle.fill")
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        }
    }

    func stepRow(title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentOrange)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: Muscle Groups

    var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("11 Muscle Groups")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(introGroups.enumerated()), id: \.element.id) { index, group in
                    HStack(spacing: 12) {
                        Text("\(group.id)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(accentOrange))

                        Image(systemName: group.icon)
                            .font(.subheadline)
                            .foregroundStyle(accentOrange)
                            .frame(width: 24)

                        Text(group.name)
                            .font(.subheadline)

                        if group.id == 11 {
                            Text("Forehead · Eyes · Jaw")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if index < introGroups.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        }
    }

    // MARK: Benefits

    var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                benefitRow("Reduces muscle tension and pain")
                benefitRow("Eases anxiety and stress")
                benefitRow("Improves sleep quality")
                benefitRow("Increases body awareness")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        }
    }

    func benefitRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(accentOrange)
                .font(.subheadline)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Begin

    var beginSection: some View {
        VStack(spacing: 10) {
            Text("~15 min session  ·  11 muscle groups  ·  Feet → Face")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showSession = true
            } label: {
                Text("Begin")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(accentOrange)
                    )
            }
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        JPMRIntroView()
    }
}
