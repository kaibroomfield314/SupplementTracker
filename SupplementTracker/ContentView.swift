import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                TodayView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
            Tab("Supplements", systemImage: "pills") {
                SupplementsView()
            }
            Tab("Blood", systemImage: "drop") {
                BloodMarkersView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Supplement.self,
            SupplementIntake.self,
            BloodTest.self,
            BloodMarkerReading.self,
            Multivitamin.self,
            MultivitaminIngredient.self,
            SupplementStack.self,
            StackItem.self,
        ], inMemory: true)
}
