import Foundation

// MARK: - Classroom Item Category

enum ClassroomCategory: String, CaseIterable {
    case furniture   = "Furniture"
    case wallDecor   = "Wall Decor"
    case accessories = "Accessories"
    case character   = "Character"
}

// MARK: - Classroom Item Model

struct ClassroomItem: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let fileName: String        // Asset/sprite reference name
    let cost: Int               // Focus Points required to unlock
    var isUnlocked: Bool
    let category: ClassroomCategory
    let emoji: String           // Quick visual reference
}


// MARK: - Default Classroom Items

extension ClassroomItem {

    /// All items available in the virtual classroom.
    static let allItems: [ClassroomItem] = [
        // Base classroom — always unlocked, free
        ClassroomItem(
            id: "classroom",
            name: "Classroom",
            description: "Your empty classroom — the foundation of your learning space.",
            fileName: "classroom_bg",
            cost: 0,
            isUnlocked: true,
            category: .furniture,
            emoji: "🏫"
        ),
        // Teacher desk — front of classroom near chalkboard
        ClassroomItem(
            id: "teacher_desk",
            name: "Teacher's Desk",
            description: "A professional teacher's desk with a lamp, apple, and lesson plans.",
            fileName: "item_teacherdesk",
            cost: 120,
            isUnlocked: false,
            category: .furniture,
            emoji: "🍎"
        ),
        // Student desk — centre of floor
        ClassroomItem(
            id: "student_desk",
            name: "Student Desk",
            description: "A scholar's desk — perfect for focused study sessions.",
            fileName: "item_desk",
            cost: 100,
            isUnlocked: false,
            category: .furniture,
            emoji: "🪑"
        ),
        // Bookshelf — right side of floor
        ClassroomItem(
            id: "bookshelf",
            name: "Rainbow Bookshelf",
            description: "A colorful bookshelf filled with knowledge and wonder.",
            fileName: "item_bookshelf",
            cost: 150,
            isUnlocked: false,
            category: .furniture,
            emoji: "📚"
        ),
        // Pencil Holder — on the student desk
        ClassroomItem(
            id: "pencil_holder",
            name: "Pencil Holder",
            description: "Keep your stationery organized and ready to go.",
            fileName: "item_pencilholder",
            cost: 75,
            isUnlocked: false,
            category: .accessories,
            emoji: "✏️"
        ),
        // Chalkboard — overlays bg chalkboard on back wall
        ClassroomItem(
            id: "chalkboard",
            name: "Welcome Board",
            description: "A warm welcome chalkboard for your classroom.",
            fileName: "item_chalkboard",
            cost: 50,
            isUnlocked: false,
            category: .wallDecor,
            emoji: "📋"
        ),
        // Clock — overlays bg clock on left wall
        ClassroomItem(
            id: "clock",
            name: "Wall Clock",
            description: "Time management starts with knowing the time!",
            fileName: "item_clock",
            cost: 100,
            isUnlocked: false,
            category: .wallDecor,
            emoji: "🕐"
        ),
        // Globe — on floor near right wall
        ClassroomItem(
            id: "globe",
            name: "Globe",
            description: "Explore the world from your classroom.",
            fileName: "item_globe",
            cost: 125,
            isUnlocked: false,
            category: .accessories,
            emoji: "🌍"
        ),
        // Plant — floor corner
        ClassroomItem(
            id: "plant",
            name: "Monstera Plant",
            description: "A touch of nature to keep your space fresh and calming.",
            fileName: "item_plant",
            cost: 80,
            isUnlocked: false,
            category: .accessories,
            emoji: "🌿"
        ),
        // Backpack — near desk on floor
        ClassroomItem(
            id: "backpack",
            name: "Backpack",
            description: "Every student needs a trusty backpack.",
            fileName: "item_backpack",
            cost: 60,
            isUnlocked: false,
            category: .accessories,
            emoji: "🎒"
        ),
        // World Map — on back wall, currently has small picture frame
        ClassroomItem(
            id: "world_map",
            name: "World Map Poster",
            description: "A colorful map poster to decorate your walls.",
            fileName: "item_worldmap",
            cost: 90,
            isUnlocked: false,
            category: .wallDecor,
            emoji: "🗺️"
        ),
        // Student figure — beside desk on floor
        ClassroomItem(
            id: "student",
            name: "Student Figure",
            description: "Your virtual study buddy! The ultimate classroom companion.",
            fileName: "item_student",
            cost: 200,
            isUnlocked: false,
            category: .character,
            emoji: "🧑‍🎓"
        ),
        // Extra empty desk
        ClassroomItem(
            id: "desk_extra",
            name: "Extra Desk",
            description: "Another desk to accommodate more students in your classroom.",
            fileName: "item_desk_empty2",
            cost: 150,
            isUnlocked: false,
            category: .furniture,
            emoji: "🪑"
        ),
        // Boy student at desk
        ClassroomItem(
            id: "desk_boy",
            name: "Boy Student",
            description: "A studious boy reading stories at his desk. Knowledge is power!",
            fileName: "item_desk_boy",
            cost: 250,
            isUnlocked: false,
            category: .character,
            emoji: "👦"
        ),
        // Girl student at desk
        ClassroomItem(
            id: "desk_girl",
            name: "Girl Student",
            description: "A diligent girl writing notes at her desk. Future scholar!",
            fileName: "item_desk_girl",
            cost: 250,
            isUnlocked: false,
            category: .character,
            emoji: "👧"
        )
    ]
}
