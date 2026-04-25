import Foundation

/// Static onboarding content — the only pre-loaded data left after Supabase migration.
/// Everything else (users, tasks, NGOs, events) is fetched from Supabase.
enum OnboardingData {

    static let pages: [(title: String, subtitle: String, imageName: String)] = [
        ("Struggling with ADHD?", "Easily distracted? Overwhelmed by simple tasks?\nDon't worry. We got you!", "o1"),
        ("Scan & Schedule", "Instantly convert your handwritten list into a smart schedule with automatic pomodoro slots", "o2"),
        ("Build Virtual Classroom", "Complete tasks to unlock upgrades and build a classroom that supports you better every day.", "o3"),
        ("Master Hyperactivity", "Access smart sensory tools, guided meditation and relaxation tools to help with your hyperactivity", "o4"),
        ("You Are Not Alone", "Connect with people who suffer from ADHD, and find your safe space", "o5")
    ]
}
