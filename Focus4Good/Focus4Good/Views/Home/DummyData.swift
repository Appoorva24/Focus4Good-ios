import Foundation

struct DummyData {

    static let currentUser = User(
        id: UUID(),
        fullName: "Appoorva Singh",
        email: "appoorva@example.com",
        passwordHash: nil,
        profileImageUrl: nil,
        authProvider: "email",
        focusPoints: 759,
        currentLevel: 3,
        bestStreak: 12,
        currentStreak: 5
    )

    static let tasks: [UserTask] = [
        UserTask(
            id: UUID(),
            userId: currentUser.id,
            categoryId: nil,
            title: "Deep focus: Design Phase",
            scheduledDate: Date(),
            scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()),
            repeatType: .never,
            priority: .high,
            isCompleted: false,
            estimatedDuration: 50,
            createdAt: Date()
        ),
        UserTask(
            id: UUID(),
            userId: currentUser.id,
            categoryId: nil,
            title: "Review community feedback",
            scheduledDate: Date(),
            scheduledTime: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date()),
            repeatType: .never,
            priority: .medium,
            isCompleted: false,
            estimatedDuration: 25,
            createdAt: Date()
        ),
        UserTask(
            id: UUID(),
            userId: currentUser.id,
            categoryId: nil,
            title: "Weekly sync meeting",
            scheduledDate: Date(),
            scheduledTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
            repeatType: .weekly,
            priority: .medium,
            isCompleted: false,
            estimatedDuration: 25,
            createdAt: Date()
        ),
        UserTask(
            id: UUID(),
            userId: currentUser.id,
            categoryId: nil,
            title: "Read research paper",
            scheduledDate: Date(),
            scheduledTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()),
            repeatType: .never,
            priority: .low,
            isCompleted: true,
            estimatedDuration: 25,
            createdAt: Date()
        )
    ]

    static let ngos: [NGO] = [
        NGO(
            id: UUID(),
            name: "Teach For India",
            location: "Mumbai, India",
            mission: "Eliminating educational inequity by placing talented graduates in low-income schools.",
            founderName: "Shaheen Mistri",
            founderPhone: "+91-22-6656-0200",
            imageUrl: nil,
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
            imageUrl: nil,
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
                description: "Join us for a one-day intensive teaching session with underprivileged children in South Delhi government schools.",
                eventType: "Teaching",
                location: "South Delhi",
                eventDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
                imageUrl: nil,
                participantCount: 24,
                creatorId: UUID()
            ),
            VolunteerEvent(
                id: UUID(),
                ngoId: ngoId,
                title: "Community Awareness Walk",
                description: "Spread awareness about education rights in local communities through an organised awareness walk.",
                eventType: "Awareness",
                location: "Connaught Place, Delhi",
                eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                startTime: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(),
                endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(),
                imageUrl: nil,
                participantCount: 50,
                creatorId: UUID()
            )
        ]
    }

    static let dailyTip = DailyTip(
        id: UUID(),
        content: "Focus on exhale — it helps maintain calmness and reduces stress instantly.",
        isActive: true
    )

    static let onboardingPages: [(title: String, subtitle: String, imageName: String)] = [
        ("Struggling with ADHD?", "Easily distracted? Overwhelmed by simple tasks?\nDon't worry. We got you!", "onboarding1"),
        ("Scan & Schedule", "Instantly convert your handwritten list into a smart schedule with automatic pomodoro slots", "onboarding2"),
        ("Build Virtual Classroom", "Complete tasks to unlock upgrades and build a classroom that supports you better every day.", "onboarding3"),
        ("Master Hyperactivity", "Access smart sensory tools, guided meditation and relaxation tools to help with your hyperactivity", "onboarding4"),
        ("You Are Not Alone", "Connect with people who suffer from ADHD, and find your safe space", "onboarding5")
    ]
}
