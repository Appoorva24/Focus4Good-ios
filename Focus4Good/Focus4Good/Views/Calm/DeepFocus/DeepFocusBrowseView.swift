//
//  DeepFocusBrowseView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Meditation Type

private struct MeditationType: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let description: String
    let icon: String
    let phases: [MeditationPhaseData]
}

struct MeditationPhaseData: Identifiable {
    let id = UUID()
    let title: String
    let instruction: String
    let durationSeconds: Int
}

// MARK: - Sample Meditations

private let meditationTypes: [MeditationType] = [
    .init(name: "Breath Awareness",
          subtitle: "Anchor your attention",
          description: "Focus on the natural rhythm of your breathing. When your mind wanders, gently return to the breath.",
          icon: "wind",
          phases: [
              .init(title: "Settle In", instruction: "Close your eyes.\nTake three deep breaths to arrive.", durationSeconds: 15),
              .init(title: "Notice", instruction: "Feel the air entering your nostrils.\nNotice the gentle rise of your chest.", durationSeconds: 30),
              .init(title: "Follow", instruction: "Follow each breath from inhale to exhale.\nDon't try to control it — just observe.", durationSeconds: 45),
              .init(title: "Refocus", instruction: "If your mind wanders, that's okay.\nGently guide your attention back to your breath.", durationSeconds: 45),
              .init(title: "Deepen", instruction: "Sink deeper into stillness.\nLet each exhale release a little more tension.", durationSeconds: 45),
              .init(title: "Return", instruction: "Slowly bring awareness to the room.\nWiggle your fingers and open your eyes.", durationSeconds: 15),
          ]),
    .init(name: "Body Scan",
          subtitle: "Release hidden tension",
          description: "Systematically move your attention through each part of your body, noticing and releasing any tension.",
          icon: "figure.mind.and.body",
          phases: [
              .init(title: "Ground", instruction: "Close your eyes and feel\nthe weight of your body.", durationSeconds: 15),
              .init(title: "Feet & Legs", instruction: "Bring awareness to your feet.\nNotice any warmth, tingling, or tension.", durationSeconds: 35),
              .init(title: "Torso", instruction: "Move attention to your stomach and chest.\nLet your belly soften with each exhale.", durationSeconds: 35),
              .init(title: "Hands & Arms", instruction: "Feel your hands resting.\nLet your arms become heavy and relaxed.", durationSeconds: 30),
              .init(title: "Neck & Head", instruction: "Release your jaw. Soften your forehead.\nLet your whole face relax.", durationSeconds: 30),
              .init(title: "Whole Body", instruction: "Feel your entire body as one.\nBreathe in calm, breathe out tension.", durationSeconds: 35),
              .init(title: "Return", instruction: "Gently wiggle your toes and fingers.\nOpen your eyes when you're ready.", durationSeconds: 15),
          ]),
    .init(name: "Visualization",
          subtitle: "Find your peaceful place",
          description: "Imagine a calm, safe place in your mind. Let it surround you with warmth and peace.",
          icon: "sparkles",
          phases: [
              .init(title: "Breathe", instruction: "Close your eyes.\nTake five slow, deep breaths.", durationSeconds: 20),
              .init(title: "Imagine", instruction: "Picture a place that feels safe and calm.\nA beach, a forest, a quiet room.", durationSeconds: 30),
              .init(title: "See", instruction: "Notice the colours and shapes around you.\nThe light, the sky, the details.", durationSeconds: 35),
              .init(title: "Hear", instruction: "Listen to the sounds in your place.\nWaves, birds, wind, or gentle silence.", durationSeconds: 35),
              .init(title: "Feel", instruction: "Feel the warmth of this place.\nLet it wrap around you like a blanket.", durationSeconds: 35),
              .init(title: "Rest", instruction: "Stay here. You are safe.\nThere is nothing you need to do.", durationSeconds: 30),
              .init(title: "Return", instruction: "Slowly let the image fade.\nBring the calm feeling back with you.", durationSeconds: 15),
          ]),
    .init(name: "Focus Anchor",
          subtitle: "Train your attention",
          description: "Perfect for ADHD minds — gently train your focus by anchoring attention to a single point.",
          icon: "scope",
          phases: [
              .init(title: "Center", instruction: "Sit comfortably.\nSoften your gaze on the circle above.", durationSeconds: 15),
              .init(title: "Anchor", instruction: "Keep your attention on one point.\nWhen it drifts, bring it back gently.", durationSeconds: 40),
              .init(title: "Breathe & Focus", instruction: "Pair your focus with your breath.\nInhale — focus in. Exhale — soften.", durationSeconds: 40),
              .init(title: "Expand", instruction: "Widen your awareness slightly.\nNotice the edges of your vision.", durationSeconds: 35),
              .init(title: "Narrow", instruction: "Bring your focus back to the center.\nSharp, gentle, steady.", durationSeconds: 35),
              .init(title: "Release", instruction: "Let go of the focus point.\nClose your eyes and breathe freely.", durationSeconds: 15),
          ]),
    .init(name: "Loving Kindness",
          subtitle: "Cultivate self-compassion",
          description: "Send warmth and kindness to yourself and others. A powerful practice for calming the inner critic.",
          icon: "heart.circle",
          phases: [
              .init(title: "Settle", instruction: "Close your eyes.\nPlace a hand on your heart.", durationSeconds: 15),
              .init(title: "Self", instruction: "Silently repeat:\n\"May I be happy.\nMay I be peaceful.\nMay I be safe.\"", durationSeconds: 40),
              .init(title: "Loved One", instruction: "Think of someone you love.\n\"May you be happy.\nMay you be peaceful.\"", durationSeconds: 35),
              .init(title: "Neutral", instruction: "Think of someone you barely know.\nSend them the same gentle wishes.", durationSeconds: 35),
              .init(title: "All Beings", instruction: "Expand to everyone, everywhere.\n\"May all beings be happy and free.\"", durationSeconds: 35),
              .init(title: "Return", instruction: "Feel the warmth in your chest.\nCarry it with you as you open your eyes.", durationSeconds: 15),
          ]),
]

// MARK: - Duration Options

private let durationOptions = [3, 5, 10, 15]

// MARK: - Constants

private let accentOrange = Color("CalmOrange")

// MARK: - DeepFocusBrowseView

@available(iOS 17.0, *)
struct DeepFocusBrowseView: View {

    @State private var selectedMeditation: MeditationType?
    @State private var selectedDuration = 5
    @State private var showSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                durationPicker
                meditationCards
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: $showSession) {
            if let meditation = selectedMeditation {
                DeepFocusSessionView(
                    meditationName: meditation.name,
                    icon: meditation.icon,
                    phases: meditation.phases,
                    totalMinutes: selectedDuration
                )
            }
        }
        .navigationTitle("Deep Focus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension DeepFocusBrowseView {

    // MARK: Header

    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundStyle(accentOrange)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(phase ? 1.06 : 1.0)
                        .opacity(phase ? 1.0 : 0.8)
                        .rotationEffect(.degrees(phase ? 3 : -3))
                } animation: { _ in
                    .easeInOut(duration: 3.0)
                }

            Text("Guided Meditation")
                .font(.title2)
                .fontWeight(.bold)

            Text("Short, guided sessions designed for restless minds. Pick a style and duration that fits your moment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: Duration Picker

    var durationPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)

            HStack(spacing: 10) {
                ForEach(durationOptions, id: \.self) { mins in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDuration = mins
                        }
                    } label: {
                        Text("\(mins) min")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedDuration == mins ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedDuration == mins
                                          ? accentOrange
                                          : accentOrange.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Meditation Cards

    var meditationCards: some View {
        VStack(spacing: 14) {
            ForEach(meditationTypes) { meditation in
                Button {
                    selectedMeditation = meditation
                    showSession = true
                } label: {
                    meditationCard(meditation)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func meditationCard(_ meditation: MeditationType) -> some View {
        HStack(spacing: 14) {
            Image(systemName: meditation.icon)
                .font(.title2)
                .foregroundStyle(accentOrange)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(accentOrange.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(meditation.subtitle)
                    .font(.caption)
                    .foregroundStyle(accentOrange)

                Text(meditation.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        DeepFocusBrowseView()
    }
}
