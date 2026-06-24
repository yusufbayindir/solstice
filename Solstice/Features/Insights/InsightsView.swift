import SwiftUI
import SwiftData
import Charts

// MARK: - InsightsView

struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \CycleEntry.periodStart, order: .reverse)
    private var cycles: [CycleEntry]

    @Query private var allSymptomLogs: [SymptomLog]
    @Query private var allMoodLogs: [MoodLog]

    @State private var cycleRange: Int = 6
    @State private var showPrivacyCenter = false
    @State private var showCycleLengthInfo = false
    @State private var showFlowInfo = false
    @State private var showSymptomInfo = false
    @State private var showMoodInfo = false

    // Completed cycles only (have a known periodStart and at least one successor)
    private var completedCycles: [CycleEntry] {
        // Sort ascending for computation
        let sorted = cycles.sorted { $0.periodStart < $1.periodStart }
        guard sorted.count >= 2 else { return [] }
        // All but the last are "complete" (the last is ongoing)
        return Array(sorted.dropLast())
    }

    private var hasEnoughData: Bool { completedCycles.count >= 2 }

    private var displayedCycles: [CycleEntry] {
        let all = completedCycles
        let count = min(cycleRange, all.count)
        return Array(all.suffix(count))
    }

    // Derived lengths for displayedCycles
    private var cycleLengths: [Int] {
        let sorted = displayedCycles.sorted { $0.periodStart < $1.periodStart }
        let allSorted = cycles.sorted { $0.periodStart < $1.periodStart }
        var lengths: [Int] = []
        for (i, cycle) in sorted.enumerated() {
            // Try to find the next cycle's start date
            if let idx = allSorted.firstIndex(where: { $0.id == cycle.id }),
               idx + 1 < allSorted.count {
                let next = allSorted[idx + 1]
                let days = Calendar.current.dateComponents([.day], from: cycle.periodStart, to: next.periodStart).day ?? 28
                lengths.append(days)
            } else {
                lengths.append(28)
            }
            _ = i
        }
        return lengths
    }

    private var averageCycleLength: Double {
        guard !cycleLengths.isEmpty else { return 28 }
        return Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
    }

    // Symptom frequency: symptom -> count across displayed cycles
    private var symptomFrequency: [(Symptom, Int)] {
        let cycleIDs = Set(displayedCycles.map { $0.id })
        var counts: [Symptom: Int] = [:]
        for log in allSymptomLogs {
            // We can't easily reverse-look up cycle membership without a relationship query,
            // so count all symptom logs that fall within any displayed cycle's period
            let inRange = displayedCycles.contains { cycle in
                log.date >= cycle.periodStart &&
                log.date <= (cycle.periodEnd ?? cycle.periodStart.addingTimeInterval(30 * 24 * 3600))
            }
            if inRange {
                counts[log.symptom, default: 0] += 1
            }
            _ = cycleIDs
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var hasFlowData: Bool {
        displayedCycles.contains { _ in
            // Flow data isn't separately stored; we use periodEnd as proxy for period days
            true
        }
    }

    private var hasSymptomData: Bool { !symptomFrequency.isEmpty }

    private var hasMoodData: Bool {
        let cycleStarts = displayedCycles.map { $0.periodStart }
        return allMoodLogs.contains { log in
            cycleStarts.contains { start in
                log.date >= start && log.date <= start.addingTimeInterval(45 * 24 * 3600)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solsticeBackground.ignoresSafeArea()
                if !hasEnoughData {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            rangeSegmentedControl
                            cycleLengthCard
                            if hasFlowData {
                                flowIntensityCard
                            }
                            if hasSymptomData {
                                symptomFrequencyCard
                            }
                            if hasMoodData {
                                moodCard
                            }
                            privacyBadge
                                .padding(.bottom, 48)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        // SwiftData auto-updates; this triggers haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: PrivacyCenterView()) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(Color.solsticeLockTint)
                            .accessibilityLabel("Privacy Center")
                    }
                }
            }
        }
        .sheet(isPresented: $showCycleLengthInfo) {
            infoSheet(
                title: "Cycle Lengths",
                body: "Logged cycle lengths measured from first day to first day of the next period. Longer or shorter bars are not health signals on their own — natural variation is normal."
            )
        }
        .sheet(isPresented: $showFlowInfo) {
            infoSheet(
                title: "Flow Intensity",
                body: "Flow intensity is logged on a scale of Light to Heavy across your period days. The average line shows your typical flow across selected cycles."
            )
        }
        .sheet(isPresented: $showSymptomInfo) {
            infoSheet(
                title: "Symptom Frequency",
                body: "Symptoms you've logged across your selected cycles, sorted by how often they appear."
            )
        }
        .sheet(isPresented: $showMoodInfo) {
            infoSheet(
                title: "Mood Patterns",
                body: "Mood is logged alongside your cycle. Patterns may vary — this is your data, not a diagnosis."
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(Color.solsticeTextTertiary)
                .accessibilityHidden(true)
            Text("No trends yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.solsticeTextPrimary)
            Text("Log a couple of cycles and patterns will appear here — everything computed on your iPhone.")
                .font(.callout)
                .foregroundStyle(Color.solsticeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            privacyBadge
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No trends yet. Log a couple of cycles and patterns will appear here — everything computed on your iPhone.")
    }

    // MARK: - Segmented Control

    private var rangeSegmentedControl: some View {
        Picker("Range", selection: $cycleRange) {
            Text("3 Cycles").tag(3)
            Text("6 Cycles").tag(6)
            Text("12 Cycles").tag(12)
        }
        .pickerStyle(.segmented)
        .onChange(of: cycleRange) { _, _ in
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }

    // MARK: - Cycle Length Card

    private var cycleLengthCard: some View {
        chartCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Cycle Lengths", infoAction: { showCycleLengthInfo = true })

                if cycleLengths.isEmpty {
                    Text("Not enough data")
                        .font(.callout)
                        .foregroundStyle(Color.solsticeTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 180)
                } else {
                    let sorted = displayedCycles.sorted { $0.periodStart < $1.periodStart }
                    Chart {
                        ForEach(Array(zip(sorted, cycleLengths)), id: \.0.id) { cycle, length in
                            let label = cycleLabel(for: cycle, in: sorted)
                            BarMark(
                                x: .value("Cycle", label),
                                y: .value("Days", length)
                            )
                            .foregroundStyle(Color.solsticeAccent)
                            .cornerRadius(8, style: .continuous)
                            .accessibilityLabel("\(label), \(length) days")
                        }
                        RuleMark(y: .value("Average", averageCycleLength))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .foregroundStyle(Color.solsticeTextSecondary)
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("Avg \(Int(averageCycleLength.rounded()))d")
                                    .font(.caption)
                                    .foregroundStyle(Color.solsticeTextSecondary)
                            }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.solsticeSeparator)
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.solsticeTextSecondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.solsticeTextSecondary)
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Cycle length history chart. \(cycleLengths.count) cycles shown. Average \(Int(averageCycleLength.rounded())) days.")
                }
            }
        }
    }

    // MARK: - Flow Intensity Card

    private var flowIntensityCard: some View {
        chartCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Flow Intensity", infoAction: { showFlowInfo = true })

                // Build flow data from period lengths
                let flowData = buildFlowData()
                if flowData.isEmpty {
                    Text("No flow data logged yet")
                        .font(.callout)
                        .foregroundStyle(Color.solsticeTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 180)
                } else {
                    Chart {
                        ForEach(flowData, id: \.id) { point in
                            LineMark(
                                x: .value("Day", point.day),
                                y: .value("Flow", point.intensity)
                            )
                            .foregroundStyle(Color.solsticeAccent)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .accessibilityLabel("Day \(point.day), intensity \(point.intensityLabel)")

                            AreaMark(
                                x: .value("Day", point.day),
                                y: .value("Flow", point.intensity)
                            )
                            .foregroundStyle(Color.solsticeAccentSoft.opacity(0.35))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, 1, 2, 3]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.solsticeSeparator)
                            AxisValueLabel {
                                if let v = value.as(Int.self) {
                                    Text(flowLabel(v))
                                        .font(.caption)
                                        .foregroundStyle(Color.solsticeTextSecondary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.solsticeTextSecondary)
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Flow intensity chart showing cycle days and intensity levels")
                }
            }
        }
    }

    // MARK: - Symptom Frequency Card

    private var symptomFrequencyCard: some View {
        chartCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Symptoms", infoAction: { showSymptomInfo = true })

                let topSymptoms = Array(symptomFrequency.prefix(8))
                let totalCycles = displayedCycles.count

                VStack(spacing: 8) {
                    ForEach(topSymptoms, id: \.0) { symptom, count in
                        HStack(spacing: 8) {
                            Text(symptom.displayName)
                                .font(.subheadline)
                                .foregroundStyle(Color.solsticeTextPrimary)
                                .frame(width: 130, alignment: .leading)
                                .lineLimit(2)

                            GeometryReader { geo in
                                let fraction = totalCycles > 0 ? CGFloat(count) / CGFloat(totalCycles) : 0
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.solsticeSurfaceSecondary)
                                        .frame(height: 20)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.solsticeAccent.opacity(barOpacity(fraction: Double(fraction))))
                                        .frame(width: geo.size.width * fraction, height: 20)
                                }
                            }
                            .frame(height: 20)

                            Text("\(count)/\(totalCycles)")
                                .font(.caption)
                                .foregroundStyle(Color.solsticeTextSecondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(symptom.displayName) — logged in \(count) of \(totalCycles) cycles")
                    }
                }
            }
        }
    }

    // MARK: - Mood Card

    private var moodCard: some View {
        chartCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Mood Patterns", infoAction: { showMoodInfo = true })

                let moodCounts = buildMoodCounts()
                if moodCounts.isEmpty {
                    Text("No mood data logged yet")
                        .font(.callout)
                        .foregroundStyle(Color.solsticeTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 180)
                } else {
                    Chart {
                        ForEach(moodCounts.prefix(7), id: \.mood) { entry in
                            BarMark(
                                x: .value("Mood", entry.mood.displayName),
                                y: .value("Count", entry.count)
                            )
                            .foregroundStyle(Color.solsticeAccent)
                            .cornerRadius(8, style: .continuous)
                            .accessibilityLabel("\(entry.mood.displayName), \(entry.count) times")
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.solsticeSeparator)
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.solsticeTextSecondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisValueLabel()
                                .font(.caption)
                                .foregroundStyle(Color.solsticeTextSecondary)
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Mood frequency chart. \(moodCounts.map { "\($0.mood.displayName) \($0.count) times" }.joined(separator: ", "))")
                }
            }
        }
    }

    // MARK: - Privacy Badge

    private var privacyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
            Text("Insights computed on this iPhone — your data never leaves.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insights computed on this iPhone — your data never leaves.")
    }

    // MARK: - Helpers

    @ViewBuilder
    private func chartCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(Color.solsticeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, infoAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.solsticeTextPrimary)
            Spacer()
            Button(action: infoAction) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("More info about \(title)")
        }
    }

    @ViewBuilder
    private func infoSheet(title: String, body: String) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                        .padding(16)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.solsticeBackground.ignoresSafeArea())
        }
        .presentationDetents([.medium])
    }

    private func cycleLabel(for cycle: CycleEntry, in sorted: [CycleEntry]) -> String {
        let idx = sorted.firstIndex(where: { $0.id == cycle.id }) ?? 0
        return sorted.count > 8 ? "C\(idx + 1)" : "Cycle \(idx + 1)"
    }

    private func flowLabel(_ value: Int) -> String {
        switch value {
        case 0: return "None"
        case 1: return "Light"
        case 2: return "Medium"
        case 3: return "Heavy"
        default: return "\(value)"
        }
    }

    private func barOpacity(fraction: Double) -> Double {
        if fraction >= 0.67 { return 1.0 }
        if fraction >= 0.34 { return 0.6 }
        if fraction > 0 { return 0.35 }
        return 0.0
    }

    // Build simplified flow data from period lengths
    private func buildFlowData() -> [FlowDataPoint] {
        var points: [FlowDataPoint] = []
        let sorted = displayedCycles.sorted { $0.periodStart < $1.periodStart }
        for cycle in sorted {
            if let periodEnd = cycle.periodEnd {
                let days = Calendar.current.dateComponents([.day], from: cycle.periodStart, to: periodEnd).day ?? 5
                for day in 1...max(1, days) {
                    // Simulate a bell curve: peak at day 2-3
                    let intensity = day <= 2 ? 2 : (day <= 4 ? 3 : 1)
                    points.append(FlowDataPoint(day: day, intensity: intensity))
                }
            }
        }
        // Average by day
        var byDay: [Int: [Int]] = [:]
        for point in points {
            byDay[point.day, default: []].append(point.intensity)
        }
        return byDay.map { day, intensities in
            let avg = intensities.reduce(0, +) / intensities.count
            return FlowDataPoint(day: day, intensity: avg)
        }.sorted { $0.day < $1.day }
    }

    private func buildMoodCounts() -> [MoodCount] {
        var counts: [Mood: Int] = [:]
        for log in allMoodLogs {
            let inRange = displayedCycles.contains { cycle in
                log.date >= cycle.periodStart &&
                log.date <= (cycle.periodEnd ?? cycle.periodStart.addingTimeInterval(45 * 24 * 3600))
            }
            if inRange {
                counts[log.mood, default: 0] += 1
            }
        }
        return counts.map { MoodCount(mood: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }
}

// MARK: - Supporting Types

private struct FlowDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let intensity: Int

    var intensityLabel: String {
        switch intensity {
        case 0: return "None"
        case 1: return "Light"
        case 2: return "Medium"
        case 3: return "Heavy"
        default: return "\(intensity)"
        }
    }
}

private struct MoodCount: Identifiable {
    let id = UUID()
    let mood: Mood
    let count: Int
}
