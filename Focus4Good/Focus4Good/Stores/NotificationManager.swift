import UserNotifications

/// Notification Manager - Handles all task notifications
class NotificationManager {
    
    static let shared = NotificationManager()
    init() {}
    
    // MARK: - Permission Handling
    
    /// Request notification permissions from user
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
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
        guard let scheduledTime = task.scheduledTime else { return }
        
        // Check permission first
        let status = await checkPermissionStatus()
        guard status == .authorized else { return }
        
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
            
            try? await UNUserNotificationCenter.current().add(request)
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
            triggerComponents.year = nil
            triggerComponents.month = nil
            triggerComponents.day = nil
            
        case .weekly:
            triggerComponents.year = nil
            triggerComponents.month = nil
            let weekday = Calendar.current.component(.weekday, from: task.scheduledDate ?? Date())
            triggerComponents.weekday = weekday
            
        case .weekdays:
            // Monday to Friday — schedule 5 separate notifications
            for weekday in 2...6 {
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
            return
            
        case .weekends:
            // Saturday and Sunday
            for weekday in [1, 7] {
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
            return
            
        case .monthly:
            triggerComponents.year = nil
            triggerComponents.month = nil
            
        case .yearly:
            triggerComponents.year = nil
            
        default:
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
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel notification for a specific task
    func cancelNotification(for taskId: UUID) async {
        let identifiers = [
            taskId.uuidString,
            "\(taskId.uuidString)-weekday-2",
            "\(taskId.uuidString)-weekday-3",
            "\(taskId.uuidString)-weekday-4",
            "\(taskId.uuidString)-weekday-5",
            "\(taskId.uuidString)-weekday-6",
            "\(taskId.uuidString)-weekend-1",
            "\(taskId.uuidString)-weekend-7"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Get count of pending notifications
    func getPendingNotificationsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
}
