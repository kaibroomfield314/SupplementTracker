import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            SupplementsView()
                .tabItem { Label("Supplements", systemImage: "pills") }

            BloodMarkersView()
                .tabItem { Label("Blood", systemImage: "drop") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
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
        ], inMemory: true)
}
