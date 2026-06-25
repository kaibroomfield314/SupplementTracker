import SwiftUI
import SwiftData
import UserNotifications
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @Query private var intakes: [SupplementIntake]
    @Query private var tests: [BloodTest]
    @Query private var readings: [BloodMarkerReading]

    @State private var exportError: String?
    @State private var jsonURL: URL?
    @State private var intakesCSVURL: URL?
    @State private var bloodCSVURL: URL?

    @AppStorage(UserPreferenceKeys.userName) private var userName: String = ""
    @AppStorage(UserPreferenceKeys.goalName) private var goalName: String = ""
    @AppStorage(UserPreferenceKeys.goalStart) private var goalStartTimestamp: Double = 0
    @AppStorage(UserPreferenceKeys.goalDays) private var goalDays: Int = 0
    @AppStorage(UserPreferenceKeys.notificationsEnabled) private var notificationsEnabled: Bool = false
    @AppStorage(UserPreferenceKeys.healthKitConnected) private var healthKitConnected: Bool = false
    @AppStorage(UserPreferenceKeys.weightUnit) private var weightUnit: String = "kg"

    @State private var showNotificationsDeniedAlert = false

    private var goalStartBinding: Binding<Date> {
        Binding(
            get: { goalStartTimestamp > 0 ? Date(timeIntervalSince1970: goalStartTimestamp) : .now },
            set: { goalStartTimestamp = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Your name", text: $userName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Shown in the home greeting. Tap your avatar circle on the dashboard to pick a photo.")
                }

                Section {
                    TextField("Goal (e.g. 12-week cut)", text: $goalName)
                    DatePicker("Start date", selection: goalStartBinding, displayedComponents: .date)
                    Stepper(value: $goalDays, in: 0...365) {
                        HStack {
                            Text("Total days")
                            Spacer()
                            Text("\(goalDays)").monospacedDigit()
                        }
                    }
                    if goalDays > 0 && !goalName.isEmpty {
                        Button(role: .destructive) {
                            goalName = ""
                            goalDays = 0
                            goalStartTimestamp = 0
                        } label: {
                            Label("Clear goal", systemImage: "xmark.circle")
                        }
                    }
                } header: {
                    Text("Current goal")
                } footer: {
                    Text("Track progress through any time-bound goal. Shows up on Home as a 'Day X of Y' card.")
                }

                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Allow Notifications", systemImage: "bell")
                    }
                    .onChange(of: notificationsEnabled) { _, on in
                        handleNotificationToggle(on)
                    }
                    if notificationsEnabled {
                        NavigationLink {
                            RemindersView()
                        } label: {
                            Label("Manage Reminders", systemImage: "list.bullet.clipboard")
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Per-stack reminders fire at the scheduled time with a Mark as Taken action that logs the full stack without opening the app.")
                }

                if HKHealthStore.isHealthDataAvailable() {
                    Section {
                        if healthKitConnected {
                            Label("Apple Health Connected", systemImage: "heart.fill")
                                .foregroundStyle(.pink)
                            Button("Refresh Health Data") {
                                Task {
                                    await HealthService.shared.requestAuthorization()
                                    await HealthService.shared.refresh()
                                }
                            }
                        } else {
                            Button {
                                Task {
                                    await HealthService.shared.requestAuthorization()
                                    healthKitConnected = true
                                    await HealthService.shared.refresh()
                                }
                            } label: {
                                Label("Connect Apple Health", systemImage: "heart.fill")
                                    .foregroundStyle(.pink)
                            }
                        }
                        Picker("Weight unit", selection: $weightUnit) {
                            Text("Metric (kg)").tag("kg")
                            Text("Imperial (lbs)").tag("lbs")
                        }
                    } header: {
                        Text("Health")
                    } footer: {
                        Text("Read-only access to body weight, workouts, sleep, and resting heart rate. Shown on the dashboard.")
                    }
                }

                Section("At a glance") {
                    LabeledContent("Supplements", value: "\(supplements.count)")
                    LabeledContent("Intakes logged", value: "\(intakes.count)")
                    LabeledContent("Blood tests", value: "\(tests.count)")
                    LabeledContent("Marker readings", value: "\(readings.count)")
                }

                Section {
                    exportRow(
                        title: "Full backup (JSON)",
                        subtitle: "Everything: supplements, intakes, blood tests.",
                        systemImage: "doc.zipper",
                        url: jsonURL,
                        prepare: { jsonURL = try ExportService.makeJSON(context: modelContext) }
                    )
                    exportRow(
                        title: "Intakes (CSV)",
                        subtitle: "Spreadsheet of every supplement intake.",
                        systemImage: "tablecells",
                        url: intakesCSVURL,
                        prepare: { intakesCSVURL = try ExportService.makeIntakesCSV(context: modelContext) }
                    )
                    exportRow(
                        title: "Blood markers (CSV)",
                        subtitle: "Spreadsheet of every blood marker reading.",
                        systemImage: "drop",
                        url: bloodCSVURL,
                        prepare: { bloodCSVURL = try ExportService.makeBloodMarkersCSV(context: modelContext) }
                    )
                } header: {
                    Text("Export")
                } footer: {
                    Text("Exports are saved to a temporary file you can share via AirDrop, Mail, Files, or any share target.")
                }

                Section {
                    Text("Data is stored locally on this device only. Export regularly to keep a backup.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Export failed", isPresented: .constant(exportError != nil), presenting: exportError) { _ in
                Button("OK") { exportError = nil }
            } message: { msg in
                Text(msg)
            }
            .alert("Notifications Disabled", isPresented: $showNotificationsDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To receive reminders, allow notifications for SupplementTracker in Settings.")
            }
        }
    }

    private func handleNotificationToggle(_ on: Bool) {
        Task {
            if on {
                let status = await NotificationScheduler.authorizationStatus()
                if status == .denied {
                    await MainActor.run {
                        notificationsEnabled = false
                        showNotificationsDeniedAlert = true
                    }
                    return
                }
                let granted = await NotificationScheduler.requestAuthorization()
                guard granted else {
                    await MainActor.run { notificationsEnabled = false }
                    return
                }
                let all = (try? modelContext.fetch(FetchDescriptor<StackReminder>())) ?? []
                await NotificationScheduler.reschedule(reminders: all)
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }

    @ViewBuilder
    private func exportRow(
        title: String,
        subtitle: String,
        systemImage: String,
        url: URL?,
        prepare: @escaping () throws -> Void
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let url {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                }
            } else {
                Button("Prepare") {
                    do { try prepare() }
                    catch { exportError = error.localizedDescription }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
