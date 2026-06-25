import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @Query private var intakes: [SupplementIntake]
    @Query private var readings: [BloodMarkerReading]
    @Query(sort: \Multivitamin.name) private var multivitamins: [Multivitamin]
    @Query(sort: \SupplementStack.name) private var stacks: [SupplementStack]

    @AppStorage(UserPreferenceKeys.lastCelebratedStreak) private var lastCelebratedStreak: Int = 0

    @State private var showingAdd = false
    @State private var prefillSupplement: Supplement?
    @State private var undoMessage: String?
    @State private var lastDeletedIntake: SupplementIntake?
    @State private var celebratingMilestone: Int?
    @State private var refreshTrigger = 0

    private var metrics: DashboardMetrics {
        _ = refreshTrigger
        return DashboardMetrics.compute(
            supplements: supplements,
            intakes: intakes,
            readings: readings
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            backdrop
            scrollContent
            FloatingAddButton {
                showingAdd = true
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)

            VStack {
                Spacer()
                if let msg = undoMessage {
                    UndoToast(
                        message: msg,
                        onUndo: { performUndo() },
                        onDismiss: { undoMessage = nil; lastDeletedIntake = nil }
                    )
                    .padding(.bottom, 78)
                }
            }
            .animation(DS.snap, value: undoMessage)
        }
        .sheet(isPresented: $showingAdd, onDismiss: { prefillSupplement = nil }) {
            AddIntakeSheet(preselected: prefillSupplement)
        }
        .onAppear { checkForMilestone() }
        .onChange(of: metrics.topStreak) { _, _ in checkForMilestone() }
    }

    private var backdrop: some View {
        GradientBackdrop()
    }

    private let bentoGap: CGFloat = 16

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: bentoGap) {
                HeroHeader()
                    .padding(.top, 6)

                if let milestone = celebratingMilestone {
                    StreakCelebrationOverlay(milestone: milestone) {
                        celebratingMilestone = nil
                    }
                    .padding(.horizontal, -16)
                }

                // MARK: AI Summary — single clinical headline above the hero
                AISummaryCard(metrics: metrics, refreshID: refreshTrigger)

                // MARK: Bento Row 1 — Hero tile (full width)
                // Editorial 88pt "X / Y" adherence number with mini ring footer.
                AdherenceHeroTile(
                    taken: metrics.todayUniqueCount,
                    target: max(metrics.typicalCount, 1),
                    progress: metrics.completionProgress
                )

                // MARK: Bento Row 2 — TripleRing tall (left 1×2) + Streak/WeekDelta stacked (right)
                HStack(alignment: .top, spacing: bentoGap) {
                    TripleRingCard(
                        vitaminsTaken: metrics.categoryBreakdown.vitaminsTakenToday,
                        vitaminsTarget: metrics.categoryBreakdown.vitaminsTarget,
                        mineralsTaken: metrics.categoryBreakdown.mineralsTakenToday,
                        mineralsTarget: metrics.categoryBreakdown.mineralsTarget,
                        otherTaken: metrics.categoryBreakdown.otherTakenToday,
                        otherTarget: metrics.categoryBreakdown.otherTarget
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(spacing: bentoGap) {
                        StreakCard(streak: metrics.topStreak)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        WeekDeltaCard(delta: metrics.weekDeltaPercent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 190)

                // MARK: Bento Row 3 — Goal counter (full width, conditional)
                GoalCounterCard()

                // MARK: Bento Row 4 — Repeat yesterday (full width, conditional)
                if !metrics.yesterdayIntakes.isEmpty {
                    RepeatYesterdayCard(
                        yesterdayCount: metrics.yesterdayIntakes.count,
                        onRepeat: repeatYesterday
                    )
                }

                // MARK: Bento Row 5 — HealthSnapshotCard (full-width tile)
                // HEALTHKIT SLOT: This is the reserved bento position for Apple Health data.
                // Size: full-width (2×1 wide). To resize to tall (1×2), wrap in an HStack
                // alongside RepeatYesterdayCard above and give each .frame(maxWidth: .infinity).
                HealthSnapshotCard()

                // MARK: Bento Row 6 — Week chart (full width)
                WeekChartCard(days: metrics.last7Days)

                // MARK: Detail section — full-width cards below the bento grid
                HeatmapCard(days: metrics.last30Days)

                MiniCalendarCard(activeDays: metrics.activeDaysThisMonth)

                RecentBloodCard(markers: metrics.recentMarkers)

                if !stacks.isEmpty {
                    StackTemplatesCard(stacks: stacks, onLog: logStack)
                }

                if !multivitamins.isEmpty {
                    MultivitaminQuickLogCard(
                        multivitamins: multivitamins,
                        onLog: logMultivitamin
                    )
                }

                if !supplements.isEmpty {
                    QuickLogStrip(
                        supplements: supplements.sorted(by: { $0.name < $1.name }),
                        onLog: { sup in
                            prefillSupplement = sup
                            showingAdd = true
                        }
                    )
                }

                TodayIntakesCard(
                    intakes: metrics.todayIntakes,
                    onDelete: { intake in deleteIntake(intake) },
                    onAdd: { showingAdd = true },
                    onDeleteAll: deleteAllToday
                )
                .padding(.bottom, 80)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .animation(DS.snap, value: metrics.todayUniqueCount)
            .animation(DS.snap, value: metrics.topStreak)
            .animation(DS.snap, value: celebratingMilestone)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            Haptics.tap(.light)
            refreshTrigger += 1
        }
    }

    // MARK: - Actions

    private func logStack(_ stack: SupplementStack) -> Int {
        do {
            let n = try StackLogger.log(stack: stack, in: modelContext)
            checkForMilestone()
            return n
        } catch { return 0 }
    }

    private func logMultivitamin(_ multi: Multivitamin, servings: Int) -> Int {
        do {
            let n = try MultivitaminLogger.log(multivitamin: multi, servings: servings, in: modelContext)
            Haptics.success()
            checkForMilestone()
            return n
        } catch { return 0 }
    }

    private func deleteIntake(_ intake: SupplementIntake) {
        lastDeletedIntake = intake
        let name = intake.supplement?.name ?? "Intake"
        modelContext.delete(intake)
        try? modelContext.save()
        undoMessage = "Deleted \(name)"
    }

    private func performUndo() {
        guard let intake = lastDeletedIntake else { return }
        let restored = SupplementIntake(
            date: intake.date,
            amount: intake.amount,
            unit: intake.unit,
            notes: intake.notes,
            supplement: intake.supplement,
            sourceMultivitamin: intake.sourceMultivitamin,
            multivitaminServings: intake.multivitaminServings
        )
        modelContext.insert(restored)
        Haptics.success()
        undoMessage = nil
        lastDeletedIntake = nil
    }

    private func deleteAllToday() {
        for intake in metrics.todayIntakes {
            modelContext.delete(intake)
        }
        try? modelContext.save()
    }

    private func repeatYesterday() -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let now = Date.now
        let offsetSeconds = now.timeIntervalSince(today)
        var created = 0
        for intake in metrics.yesterdayIntakes {
            let yStart = cal.startOfDay(for: intake.date)
            let timeOfDay = intake.date.timeIntervalSince(yStart)
            // Prefer the original time of day; if it would land in the future, use 'now'
            let proposed = today.addingTimeInterval(timeOfDay)
            let when = proposed > now ? today.addingTimeInterval(offsetSeconds) : proposed
            let copy = SupplementIntake(
                date: when,
                amount: intake.amount,
                unit: intake.unit,
                notes: intake.notes,
                supplement: intake.supplement,
                sourceMultivitamin: intake.sourceMultivitamin,
                multivitaminServings: intake.multivitaminServings
            )
            modelContext.insert(copy)
            created += 1
        }
        try? modelContext.save()
        return created
    }

    private func checkForMilestone() {
        guard let streak = metrics.topStreak?.days,
              let milestone = StreakMilestones.milestone(for: streak),
              milestone > lastCelebratedStreak else { return }
        celebratingMilestone = milestone
        lastCelebratedStreak = milestone
    }
}

struct QuickLogStrip: View {
    let supplements: [Supplement]
    let onLog: (Supplement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Quick log", trailing: "\(supplements.count)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(supplements) { sup in
                        QuickLogChip(supplement: sup, onTap: { onLog(sup) })
                    }
                }
            }
        }
        .cardSurface()
    }
}

private struct QuickLogChip: View {
    let supplement: Supplement
    let onTap: () -> Void

    var body: some View {
        Button {
            Haptics.tap(.light)
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: supplement.category.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(supplement.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                if supplement.defaultDose > 0 {
                    Text("\(supplement.defaultDose.clean) \(supplement.unit)")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .font(.system(size: 10))
                }
            }
            .frame(width: 120, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: DS.chipRadius, style: .continuous)
                    .fill(DS.chipBG)
            )
        }
        .buttonStyle(.plain)
    }
}

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%g", self)
    }
}
