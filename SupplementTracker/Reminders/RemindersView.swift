import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StackReminder.hour) private var reminders: [StackReminder]
    @State private var showingAdd = false

    var body: some View {
        List {
            if reminders.isEmpty {
                EmptyStateIllustration(
                    imageName: "NoRemindersEmptyState",
                    headline: "No reminders set"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder) {
                        reschedule(reminders)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Reminders")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddReminderSheet()
        }
    }

    private func delete(at offsets: IndexSet) {
        let remaining = reminders.indices
            .filter { !offsets.contains($0) }
            .map { reminders[$0] }
        for i in offsets { modelContext.delete(reminders[i]) }
        reschedule(remaining)
    }

    private func reschedule(_ list: [StackReminder]) {
        Task { await NotificationScheduler.reschedule(reminders: list) }
    }
}

// MARK: - Reminder row

private struct ReminderRow: View {
    @Bindable var reminder: StackReminder
    var onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(reminder.stack?.emoji ?? "💊") \(reminder.stack?.name ?? "—")")
                Text("\(daysLabel) · \(timeLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $reminder.isEnabled)
                .labelsHidden()
                .onChange(of: reminder.isEnabled) { _, _ in onToggle() }
        }
        .padding(.vertical, 2)
    }

    private var daysLabel: String {
        let days = reminder.weekdays
        if days.count == 7 { return "Every day" }
        if days == Set([Weekday.monday, .tuesday, .wednesday, .thursday, .friday]) { return "Weekdays" }
        if days == Set([Weekday.saturday, .sunday]) { return "Weekends" }
        return Weekday.allCases.filter { days.contains($0) }.map(\.twoLetter).joined(separator: ", ")
    }

    private var timeLabel: String {
        var c = DateComponents()
        c.hour = reminder.hour
        c.minute = reminder.minute
        guard let date = Calendar.current.date(from: c) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Add reminder sheet

struct AddReminderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SupplementStack.name) private var stacks: [SupplementStack]

    @State private var selectedStack: SupplementStack?
    @State private var selectedWeekdays: Set<Weekday> = Set(Weekday.allCases)
    @State private var fireTime: Date = {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Stack") {
                    if stacks.isEmpty {
                        Text("Create a stack first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Stack", selection: $selectedStack) {
                            Text("Select…").tag(SupplementStack?.none)
                            ForEach(stacks) { stack in
                                Text("\(stack.emoji) \(stack.name)")
                                    .tag(SupplementStack?.some(stack))
                            }
                        }
                    }
                }

                Section("Schedule") {
                    WeekdayPickerRow(selected: $selectedWeekdays)
                    DatePicker("Time", selection: $fireTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("New Reminder")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(selectedStack == nil || selectedWeekdays.isEmpty || stacks.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let stack = selectedStack else { return }
        let cal = Calendar.current
        let reminder = StackReminder(
            stack: stack,
            weekdays: selectedWeekdays,
            hour: cal.component(.hour, from: fireTime),
            minute: cal.component(.minute, from: fireTime)
        )
        modelContext.insert(reminder)
        let all = (try? modelContext.fetch(FetchDescriptor<StackReminder>())) ?? []
        Task { await NotificationScheduler.reschedule(reminders: all) }
        dismiss()
    }
}

// MARK: - Weekday picker

private struct WeekdayPickerRow: View {
    @Binding var selected: Set<Weekday>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { day in
                Button {
                    if selected.contains(day) {
                        selected.remove(day)
                    } else {
                        selected.insert(day)
                    }
                } label: {
                    Text(day.twoLetter)
                        .font(.caption.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle().fill(selected.contains(day) ? Color.accentColor : DS.chipBG)
                        )
                        .foregroundStyle(selected.contains(day) ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}
