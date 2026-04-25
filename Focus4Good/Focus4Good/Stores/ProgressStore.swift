import Foundation
import Supabase

@MainActor
@Observable
class ProgressStore {
    
    var progressRecords: [UserProgress] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Computed properties — UNCHANGED
    var dailyProgress: UserProgress? {
        progressRecords.first { $0.periodType == "daily" && Calendar.current.isDateInToday($0.periodStart) }
    }
    var weeklyProgress: UserProgress? {
        progressRecords.first { $0.periodType == "weekly" && Calendar.current.isDate($0.periodStart, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    var monthlyProgress: UserProgress? {
        progressRecords.first { $0.periodType == "monthly" && Calendar.current.isDate($0.periodStart, equalTo: Date(), toGranularity: .month) }
    }
    
    static let shared = ProgressStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}
    
    // MARK: - Fetch from Supabase
    func fetchProgress(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [UserProgress] = try await client
                .from("user_progress")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            progressRecords = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Updates
    func incrementTasksCompleted(userId: UUID) async {
        await upsertProgress(userId: userId) { $0.tasksCompleted += 1 }
    }
    
    func addFocusTime(minutes: Int, userId: UUID) async {
        await upsertProgress(userId: userId) { $0.focusTimeMinutes += minutes }
    }
    
    func addCalmCentreTime(minutes: Int, userId: UUID) async {
        await upsertProgress(userId: userId) { $0.calmCentreMinutes += minutes }
    }
    
    func addPointsEarned(points: Int, userId: UUID) async {
        await upsertProgress(userId: userId) { $0.focusPointsEarned += points }
    }
    
    // MARK: - Upsert (Create or Update)
    private func upsertProgress(userId: UUID, mutation: (inout UserProgress) -> Void) async {
        for periodType in ["daily", "weekly", "monthly"] {
            let start = periodStart(for: periodType)
            
            if let index = progressRecords.firstIndex(where: {
                $0.periodType == periodType && Calendar.current.isDate($0.periodStart, inSameDayAs: start)
            }) {
                // UPDATE existing record
                mutation(&progressRecords[index])
                do {
                    try await client
                        .from("user_progress")
                        .update(progressRecords[index])
                        .eq("id", value: progressRecords[index].id.uuidString)
                        .execute()
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                // INSERT new record
                var newRecord = UserProgress(
                    userId: userId,
                    periodType: periodType,
                    periodStart: start,
                    tasksCompleted: 0,
                    focusTimeMinutes: 0,
                    calmCentreMinutes: 0,
                    focusPointsEarned: 0,
                    taskGoal: defaultTaskGoal(for: periodType)
                )
                mutation(&newRecord)
                do {
                    let inserted: UserProgress = try await client
                        .from("user_progress")
                        .insert(newRecord)
                        .select()
                        .single()
                        .execute()
                        .value
                    progressRecords.append(inserted)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func periodStart(for periodType: String) -> Date {
        let calendar = Calendar.current
        switch periodType {
        case "weekly": return calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        case "monthly": return calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        default: return calendar.startOfDay(for: Date())
        }
    }
    
    private func defaultTaskGoal(for periodType: String) -> Int {
        switch periodType {
        case "daily": return 15
        case "weekly": return 75
        case "monthly": return 300
        default: return 15
        }
    }
}

