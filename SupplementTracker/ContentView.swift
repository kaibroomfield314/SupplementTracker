import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab { TodayView() } label: {
                Label { Text("Home") } icon: {
                    Image(systemName: "house.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.indigo)
                }
            }
            Tab { HistoryView() } label: {
                Label { Text("History") } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.orange)
                }
            }
            Tab { SupplementsView() } label: {
                Label { Text("Supplements") } icon: {
                    Image(systemName: "pills.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green)
                }
            }
            Tab { BloodMarkersView() } label: {
                Label { Text("Blood") } icon: {
                    Image(systemName: "drop.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red)
                }
            }
            Tab { SettingsView() } label: {
                Label { Text("Settings") } icon: {
                    Image(systemName: "gearshape.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.gray)
                }
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
        ], inMemory: true)
}
