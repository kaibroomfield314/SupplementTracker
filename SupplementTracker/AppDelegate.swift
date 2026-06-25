import UIKit
import UserNotifications
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Supplement.self,
            SupplementIntake.self,
            BloodTest.self,
            BloodMarkerReading.self,
            Multivitamin.self,
            MultivitaminIngredient.self,
            SupplementStack.self,
            StackItem.self,
            StackReminder.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationScheduler.registerCategories()
        backfillIngredientFlag()
        return true
    }

    private func backfillIngredientFlag() {
        let context = ModelContext(sharedModelContainer)
        guard let all = try? context.fetch(FetchDescriptor<Supplement>()) else { return }
        var dirty = false
        for sup in all where !sup.isIngredient && sup.notes == "Auto-created from multivitamin ingredient" {
            sup.isIngredient = true
            dirty = true
        }
        if dirty { try? context.save() }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    // Handle notification action responses (e.g. "Mark as Taken")
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard
            response.actionIdentifier == NotificationScheduler.markTakenActionID,
            let uuidString = response.notification.request.content.userInfo["reminderUUID"] as? String,
            let uuid = UUID(uuidString: uuidString)
        else { return }

        let context = ModelContext(sharedModelContainer)
        let predicate = #Predicate<StackReminder> { $0.reminderId == uuid }
        guard
            let reminder = try? context.fetch(FetchDescriptor(predicate: predicate)).first,
            let stack = reminder.stack
        else { return }

        try? StackLogger.log(stack: stack, at: .now, in: context)
        try? context.save()
    }

    // Show banner + play sound even when app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
