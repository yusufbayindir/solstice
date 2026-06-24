import SwiftUI
import SwiftData

// MARK: - HomeDashboardView

struct HomeDashboardView: View {

    // MARK: - Data

    @Query(sort: \CycleEntry.periodStart, order: .reverse)
    private var cycles: [CycleEntry]

    @Query private var settingsArray: [AppSettings]

    @Environment(\.predictionEngine) private var predictionEngine
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    private var settings: AppSettings? { settingsArray.first }

    // MARK: - Derived State

    private var prediction: PredictionResult? {
        guard let settings else { return nil }
        return predictionEngine.nextPeriodDate(from: cycles, settings: settings)
    }

    private var cycleDay: Int {
        guard let lastCycle = cycles.first else { return 1 }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: lastCycle.periodStart, to: Date()).day ?? 0
        return max(1, days + 1)
    }

    private var cycleLength: Int {
        settings?.averageCycleLength ?? 28
    }

    private var periodLength: Int {
        settings?.averagePeriodLength ?? 5
    }

    private var phaseLabel: String {
        guard let pred = prediction else {
            return "Tracking your cycle"
        }
        if pred.daysUntilNextPeriod == 0 {
            return "Period expected today"
        }
        if pred.daysUntilNextPeriod < 0 {
            return "Period may be late"
        }
        return "Period in \(pred.daysUntilNextPeriod) days"
    }

    private var ringViewModel: CycleRingView.ViewModel {
        guard let pred = prediction, let settings else {
            return CycleRingView.ViewModel(
                cycleDay: 1,
                cycleLength: cycleLength,
                periodLength: periodLength,
                fertileWindowStartDay: 0,
                fertileWindowLength: 0,
                ovulationDay: 0,
                isPeriodPredicted: true,
                confidence: nil,
                phaseLabel: "",
                hasData: false
            )
        }

        let cal = Calendar.current
        let totalDays = cycleLength
        let lastPeriodStart = cycles.first?.periodStart ?? (settings.lastPeriodStart ?? Date())

        // Compute fertile window start day offset
        let fertileStart = pred.fertileWindow.start
        let fertileStartOffset = cal.dateComponents([.day], from: lastPeriodStart, to: fertileStart).day ?? 0
        let fertileLength = Int(pred.fertileWindow.duration / 86_400)

        // Ovulation day offset
        let ovOffset = cal.dateComponents([.day], from: lastPeriodStart, to: pred.ovulationDate).day ?? 0

        let isPredicted = cycles.isEmpty

        return CycleRingView.ViewModel(
            cycleDay: cycleDay,
            cycleLength: totalDays,
            periodLength: periodLength,
            fertileWindowStartDay: max(0, fertileStartOffset),
            fertileWindowLength: max(0, fertileLength),
            ovulationDay: max(0, ovOffset),
            isPeriodPredicted: isPredicted,
            confidence: pred.confidence,
            phaseLabel: phaseLabel,
            hasData: !cycles.isEmpty || settings.lastPeriodStart != nil
        )
    }

    // MARK: - Body

    var body: some View {
        @Bindable var appState = appState
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    if cycles.isEmpty && settings?.lastPeriodStart == nil {
                        emptyState
                    } else {
                        populatedContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // FAB clearance
            }
            .background(Color.solsticeBackground)
            .refreshable {
                // Local computation — no async work needed, just trigger a re-render
            }

            // FAB
            fabButton
                .padding(.trailing, 20)
                .padding(.bottom, 32)
        }
        .sheet(isPresented: $appState.showLogEntry) {
            LogEntryView(initialDate: Date())
        }
        .navigationTitle(todayTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.selectedTab = .settings
                } label: {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(Color.solsticeLockTint)
                        .accessibilityLabel("Privacy Center")
                }
                .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Today title

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            VStack(spacing: 16) {
                Image(systemName: "drop")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.solsticeTextTertiary)
                    .accessibilityHidden(true)

                Text("Start tracking\nyour first cycle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Log your period to get personalized predictions — all computed on your iPhone.")
                    .font(.callout)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    appState.showLogEntry = true
                } label: {
                    Label("Log period", systemImage: "drop.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(Color.solsticeAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityLabel("Log period")
            }
            .padding(16)
            .background(Color.solsticeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

            privacyBadge
        }
    }

    // MARK: - Populated Content

    private var populatedContent: some View {
        VStack(spacing: 24) {
            // Hero: Cycle Ring Card
            cycleRingCard

            // Prediction summary card
            if let pred = prediction {
                predictionCard(pred)
            }

            // Quick-log strip
            quickLogStrip

            // Recent entries
            if !cycles.isEmpty {
                recentEntriesSection
            }

            // Privacy footer
            privacyBadge
        }
    }

    // MARK: - Cycle Ring Card

    private var cycleRingCard: some View {
        VStack(spacing: 0) {
            CycleRingView(viewModel: ringViewModel, diameter: 260)
                .padding(.vertical, 16)
                .onTapGesture {
                    appState.selectedTab = .calendar
                }
                .accessibilityHint("Double-tap to view calendar")

            if prediction?.confidence == .low {
                Text("Estimate improves as you log more.")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.solsticeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Prediction Card

    private func predictionCard(_ pred: PredictionResult) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Predictions")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.solsticeTextPrimary)
                Spacer()
                // Confidence badge
                Text(pred.confidence.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.solsticeSurfaceSecondary)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                predictionRow(
                    symbol: "drop.fill",
                    color: .solsticePeriod,
                    label: "Next period",
                    value: nextPeriodText(pred)
                )
                Divider().padding(.leading, 44)
                predictionRow(
                    symbol: "leaf.fill",
                    color: .solsticeFertile,
                    label: "Fertile window",
                    value: fertileWindowText(pred)
                )
                Divider().padding(.leading, 44)
                predictionRow(
                    symbol: "sparkle",
                    color: .solsticeOvulation,
                    label: "Ovulation",
                    value: ovulationText(pred)
                )
            }
        }
        .padding(16)
        .background(Color.solsticeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func predictionRow(symbol: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            Text(label)
                .font(.body)
                .foregroundStyle(Color.solsticeTextPrimary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(Color.solsticeTextSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    // MARK: - Quick-log Strip

    private var quickLogStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.solsticeTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickLogChip(symbol: "drop.fill", label: "Log period") {
                        appState.showLogEntry = true
                    }
                    quickLogChip(symbol: "drop.halffull", label: "Flow") {
                        appState.showLogEntry = true
                    }
                    quickLogChip(symbol: "bolt.heart", label: "Symptoms") {
                        appState.showLogEntry = true
                    }
                    quickLogChip(symbol: "face.smiling", label: "Mood") {
                        appState.showLogEntry = true
                    }
                }
                .padding(.horizontal, 1) // avoid clip
            }
        }
        .padding(16)
        .background(Color.solsticeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func quickLogChip(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                    .accessibilityHidden(true)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.solsticeAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.solsticeAccentSoft)
            .clipShape(Capsule())
        }
        .frame(minHeight: 44)
        .accessibilityLabel(label)
    }

    // MARK: - Recent Entries

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent cycles")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.solsticeTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(cycles.prefix(3)), id: \.id) { entry in
                    recentEntryRow(entry)
                    if entry.id != cycles.prefix(3).last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.solsticeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func recentEntryRow(_ entry: CycleEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.solsticePeriod)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.periodStart, style: .date)
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)

                if let end = entry.periodEnd {
                    let days = Calendar.current.dateComponents([.day], from: entry.periodStart, to: end).day ?? 0
                    Text("\(days + 1) days")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            appState.showLogEntry = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.headline)
                    .accessibilityHidden(true)
                Text("Log")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color.solsticeAccent)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 6)
        }
        .accessibilityLabel("Log")
    }

    // MARK: - Privacy Badge

    private var privacyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
            Text("On this iPhone")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your data stays on this iPhone")
    }

    // MARK: - Formatting Helpers

    private func nextPeriodText(_ pred: PredictionResult) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let days = pred.daysUntilNextPeriod
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow · \(formatter.string(from: pred.nextPeriod))" }
        return "in \(days) days · \(formatter.string(from: pred.nextPeriod))"
    }

    private func fertileWindowText(_ pred: PredictionResult) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: pred.fertileWindow.start)
        let end = formatter.string(from: pred.fertileWindow.end)
        return "\(start) – \(end)"
    }

    private func ovulationText(_ pred: PredictionResult) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: pred.ovulationDate)) (est.)"
    }
}
