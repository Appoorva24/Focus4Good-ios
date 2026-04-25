import Foundation

struct DummyData {

    static let currentUser = User(
        id: UUID(),
        fullName: "Appoorva Khajuria",
        email: "appoorva2025@gmail.com",
        passwordHash: nil,
        profileImageUrl: nil,
        authProvider: "email",
        focusPoints: 5000,
        currentLevel: 1,
        bestStreak: 0,
        currentStreak: 0
    )

    // No pre-loaded tasks — user adds their own
    static let tasks: [UserTask] = []

    static let ngos: [NGO] = [
        NGO(
            id: UUID(),
            name: "Teach For India",
            location: "Mumbai, India",
            mission: "Eliminating educational inequity by placing talented graduates in low-income schools.",
            founderName: "Shaheen Mistri",
            founderPhone: "+91-22-6656-0200",
            imageName: "ngo",
            studentCount: 38000,
            yearsActive: 15,
            projectCount: 12,
            isVerified: true
        ),
        NGO(
            id: UUID(),
            name: "Pratham",
            location: "Delhi, India",
            mission: "Improving quality of education for underprivileged children across India.",
            founderName: "Madhav Chavan",
            founderPhone: "+91-11-4141-0000",
            imageName: "ngo",
            studentCount: 75000,
            yearsActive: 28,
            projectCount: 20,
            isVerified: true
        )
    ]

    static func volunteerEvents(for ngoId: UUID) -> [VolunteerEvent] {
        [
            VolunteerEvent(
                id: UUID(),
                ngoId: ngoId,
                title: "Teaching Drive — South Delhi",
                location: "South Delhi",
                eventDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                participantCount: 24
            ),
            VolunteerEvent(
                id: UUID(),
                ngoId: ngoId,
                title: "Community Awareness Walk",
                location: "Connaught Place, Delhi",
                eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                participantCount: 50
            )
        ]
    }



    static let onboardingPages: [(title: String, subtitle: String, imageName: String)] = [
        ("Struggling with ADHD?", "Easily distracted? Overwhelmed by simple tasks?\nDon't worry. We got you!", "o1"),
        ("Plan Your Day", "Easily create tasks and manage your daily schedule with smart pomodoro sessions", "o2"),
        ("Build Virtual Classroom", "Complete tasks to unlock upgrades and build a classroom that supports you better every day.", "o3"),
        ("Master Hyperactivity", "Access smart sensory tools, guided meditation and relaxation tools to help with your hyperactivity", "o4"),
        ("You Are Not Alone", "Connect with people who suffer from ADHD, and find your safe space", "o5")
    ]
}
