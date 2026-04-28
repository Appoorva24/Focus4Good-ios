import Foundation

// MARK: - Classroom Store

/// Manages the state of the virtual classroom — which items are unlocked,
/// persists unlock state to UserDefaults, and handles Focus Point spending.
/// Also stores custom item positions set by the user via drag-and-drop.
///
@MainActor
@Observable
class ClassroomStore {

    // MARK: - Singleton
    static let shared = ClassroomStore()

    // MARK: - State
    var items: [ClassroomItem]

    /// Custom positions set by the user (item id → CGPoint offset from default)
    var customPositions: [String: [CGFloat]] = [:]

    /// Custom rotation angles set by the user (item id → degrees)
    var customRotations: [String: Double] = [:]

    /// Items the user has already unlocked
    var unlockedItems: [ClassroomItem] {
        items.filter { $0.isUnlocked }
    }

    /// Items still locked
    var lockedItems: [ClassroomItem] {
        items.filter { !$0.isUnlocked }
    }

    /// Progress fraction (0...1)
    var progress: Double {
        Double(unlockedItems.count) / Double(items.count)
    }

    /// Total Focus Points spent so far
    var totalSpent: Int {
        items.filter { $0.isUnlocked && $0.cost > 0 }
            .reduce(0) { $0 + $1.cost }
    }

    // MARK: - Persistence Keys
    private let unlockedKey = "unlockedClassroomItems"
    private let positionsKey = "classroomItemPositions"
    private let rotationsKey = "classroomItemRotations"

    // MARK: - Init
    init() {
        // Start with all default items
        var loadedItems = ClassroomItem.allItems

        // Restore previously unlocked items
        let savedIDs = Set(UserDefaults.standard.stringArray(forKey: unlockedKey) ?? [])
        for i in loadedItems.indices {
            if savedIDs.contains(loadedItems[i].id) {
                loadedItems[i].isUnlocked = true
            }
        }

        self.items = loadedItems

        // Restore custom positions
        if let savedPositions = UserDefaults.standard.dictionary(forKey: positionsKey) as? [String: [CGFloat]] {
            self.customPositions = savedPositions
        }
        if let savedRotations = UserDefaults.standard.dictionary(forKey: rotationsKey) as? [String: Double] {
            self.customRotations = savedRotations
        }
    }

    // MARK: - Actions

    /// Check if user can afford a given item
    func canAfford(_ item: ClassroomItem, userStore: UserStore) -> Bool {
        (userStore.currentUser?.focusPoints ?? 0) >= item.cost
    }

    /// Unlock an item by spending Focus Points
    /// Returns true if successful, false if insufficient points or already unlocked.
    @discardableResult
    func unlockItem(id: String, userStore: UserStore) async -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        guard !items[index].isUnlocked else { return false }

        let cost = items[index].cost
        guard (userStore.currentUser?.focusPoints ?? 0) >= cost else { return false }

        // Deduct Focus Points
        await userStore.updateFocusPoints(by: -cost)

        // Mark as unlocked
        items[index].isUnlocked = true

        // Persist
        persistUnlocked()
        return true
    }

    // MARK: - Position Management

    /// Save a custom position for an item
    func setCustomPosition(for itemID: String, x: CGFloat, y: CGFloat) {
        customPositions[itemID] = [x, y]
        persistPositions()
    }

    /// Get the custom position for an item (nil if using default)
    func customPosition(for itemID: String) -> (x: CGFloat, y: CGFloat)? {
        guard let pos = customPositions[itemID], pos.count == 2 else { return nil }
        return (pos[0], pos[1])
    }

    // MARK: - Rotation Management

    /// Save a custom rotation for an item (in degrees)
    func setCustomRotation(for itemID: String, degrees: Double) {
        customRotations[itemID] = degrees
        persistRotations()
    }

    /// Get the custom rotation for an item (nil if using default = 0°)
    func customRotation(for itemID: String) -> Double {
        customRotations[itemID] ?? 0
    }

    /// Reset all items to their default positions and rotations
    func resetAllPositions() {
        customPositions.removeAll()
        customRotations.removeAll()
        persistPositions()
        persistRotations()
    }

    /// Unlock all items for a brand-new user (no points deducted — it's a bonus)
    func unlockAllForNewUser() {
        for i in items.indices {
            items[i].isUnlocked = true
        }
        persistUnlocked()
        print("🎁 All classroom items unlocked for new user")
    }

    /// Clear all data (called on sign-out)
    func clearData() {
        items = ClassroomItem.allItems
        customPositions.removeAll()
        customRotations.removeAll()
        // Also wipe UserDefaults so a fresh login starts with a clean classroom
        UserDefaults.standard.removeObject(forKey: unlockedKey)
        UserDefaults.standard.removeObject(forKey: positionsKey)
        UserDefaults.standard.removeObject(forKey: rotationsKey)
    }

    /// Reset all items (for testing/debug)
    func resetAll() {
        for i in items.indices {
            items[i].isUnlocked = items[i].cost == 0 // Only classroom base stays unlocked
        }
        persistUnlocked()
        resetAllPositions()
    }

    private func persistRotations() {
        UserDefaults.standard.set(customRotations, forKey: rotationsKey)
    }

    // MARK: - Persistence

    private func persistUnlocked() {
        let unlockedIDs = items.filter { $0.isUnlocked }.map { $0.id }
        UserDefaults.standard.set(unlockedIDs, forKey: unlockedKey)
    }

    private func persistPositions() {
        UserDefaults.standard.set(customPositions, forKey: positionsKey)
    }
}
