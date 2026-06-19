import SwiftUI
import SwiftData

@main
struct SupplementTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Supplement.self,
            SupplementIntake.self,
            BloodTest.self,
            BloodMarkerReading.self,
            Multivitamin.self,
            MultivitaminIngredient.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
