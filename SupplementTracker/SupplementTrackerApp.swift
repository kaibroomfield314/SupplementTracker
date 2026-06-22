import SwiftUI
import SwiftData

@main
struct SupplementTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(appDelegate.sharedModelContainer)
    }
}
