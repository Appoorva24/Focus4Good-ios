import Foundation
import UserNotifications

/// Notification Manager - Handles all task notifications
@MainActor
final class NotificationManager {
    
    static let shared = NotificationManager()
    private init() {}
    
    // MARK: - Permission Handling
    
    /// Request notification permissions from user
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }
    
    /// Check current notification permission status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule notification for a task
    func scheduleNotification(for task: UserTask) async {
        // Cancel any existing notification for this task
        await cancelNotification(for: task.id)
        
        // Only schedule if task has time set
        guard let scheduledTime = task.scheduledTime else {
            print("⚠️ No time set for task, skipping notification")
            return
        }
        
        // Check permission first
        let status = await checkPermissionStatus()
        guard status == .authorized else {
            print("⚠️ Notifications not authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        
        // Add priority info if high
        if task.priority == .high {
            content.subtitle = "⚠️ High Priority"
        }
        
        // Create date components for trigger
        let taskDate = task.scheduledDate ?? Date()
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: taskDate
        )
        
        let timeComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: scheduledTime
        )
        
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        // Check if task is for repeat type
        if task.repeatType != .never {
            await scheduleRepeatingNotification(for: task, content: content, dateComponents: dateComponents)
        } else {
            // One-time notification
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: task.id.uuidString,
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Notification scheduled for: \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
            } catch {
                print("❌ Error scheduling notification: \(error)")
            }
        }
    }
    
    /// Schedule repeating notification for recurring tasks
    private func scheduleRepeatingNotification(
        for task: UserTask,
        content: UNMutableNotificationContent,
        dateComponents: DateComponents
    ) async {
        var triggerComponents = dateComponents
        
        // Configure repeat based on task repeat type
        switch task.repeatType {
        case .daily:
            // Repeat daily at same time
            triggerComponents.year = nil
            triggerComponents.month = nil
            triggerComponents.day = nil
            
        case .weekly:
            // Repeat weekly on same day
            triggerComponents.year = nil
            triggerComponents.month = nil
            let weekday = Calendar.current.component(.weekday, from: task.scheduledDate ?? Date())
            triggerComponents.weekday = weekday
            
        case .weekdays:
            // Monday to Friday only
            // We need to schedule 5 separate notifications
            for weekday in 2...6 { // Monday=2 to Friday=6
                var weekdayComponents = triggerComponents
                weekdayComponents.year = nil
                weekdayComponents.month = nil
                weekdayComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: weekdayComponents,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "\(task.id.uuidString)-weekday-\(weekday)",
                    content: content,
                    trigger: trigger
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
            print("✅ Weekday notifications scheduled")
            return
            
        case .weekends:
            // Saturday and Sunday only
            for weekday in [1, 7] { // Sunday=1, Saturday=7
                var weekendComponents = triggerComponents
                weekendComponents.year = nil
                weekendComponents.month = nil
                weekendComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: weekendComponents,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "\(task.id.uuidString)-weekend-\(weekday)",
                    content: content,
                    trigger: trigger
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
            print("✅ Weekend notifications scheduled")
            return
            
        case .monthly:
            // Repeat on same day of month
            triggerComponents.year = nil
            triggerComponents.month = nil
            
        case .yearly:
            // Repeat yearly on same date
            triggerComponents.year = nil
            
        default:
            // For other repeat types, use one-time notification
            triggerComponents.year = nil
            triggerComponents.month = nil
            triggerComponents.day = nil
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Repeating notification scheduled for \(task.repeatType)")
        } catch {
            print("❌ Error scheduling repeating notification: \(error)")
        }
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel notification for a specific task
    func cancelNotification(for taskId: UUID) async {
        let identifiers = [
            taskId.uuidString,
            // Also cancel weekday variations if any
            "\(taskId.uuidString)-weekday-2",
            "\(taskId.uuidString)-weekday-3",
            "\(taskId.uuidString)-weekday-4",
            "\(taskId.uuidString)-weekday-5",
            "\(taskId.uuidString)-weekday-6",
            // Also cancel weekend variations
            "\(taskId.uuidString)-weekend-1",
            "\(taskId.uuidString)-weekend-7"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
        
        print("✅ Cancelled notification for task: \(taskId)")
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ All notifications cancelled")
    }
    
    // MARK: - Debug Helpers
    
    /// Get count of pending notifications (for debugging)
    func getPendingNotificationsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📊 Pending notifications: \(requests.count)")
        return requests.count
    }
    
    /// Print all pending notifications (for debugging)
    func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("\n📋 Pending Notifications (\(requests.count)):")
        for request in requests {
            print("  - ID: \(request.identifier)")
            print("    Title: \(request.content.title)")
            print("    Body: \(request.content.body)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("    Next trigger: \(trigger.nextTriggerDate() ?? Date())")
            }
            print("")
        }
    }
}
