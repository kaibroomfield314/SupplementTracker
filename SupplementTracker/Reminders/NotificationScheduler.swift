import Foundation
import UserNotifications

enum NotificationScheduler {
    static let categoryID = "STACK_REMINDER"
    static let markTakenActionID = "MARK_TAKEN"

    static func registerCategories() {
        let action = UNNotificationAction(
            identifier: markTakenActionID,
            title: "Mark as Taken",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: [action],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func reschedule(reminders: [StackReminder]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        for reminder in reminders where reminder.isEnabled {
            guard let stack = reminder.stack else { continue }
            for weekday in reminder.weekdays {
                let content = UNMutableNotificationContent()
                content.title = "\(stack.emoji) \(stack.name)"
                content.body = "Time to take your \(stack.name) stack"
                content.sound = .default
                content.categoryIdentifier = categoryID
                content.userInfo = ["reminderUUID": reminder.reminderId.uuidString]

                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                components.weekday = weekday.rawValue

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let requestID = "\(reminder.reminderId.uuidString)-\(weekday.rawValue)"
                let request = UNNotificationRequest(
                    identifier: requestID,
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}
