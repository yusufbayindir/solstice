import Testing
import Foundation
@testable import Solstice

// MARK: - Test Helpers

private func makeSettings(
    averageCycleLength: Int = 28,
    averagePeriodLength: Int = 5,
    lastPeriodStart: Date? = nil
) -> AppSettings {
    AppSettings(
        averageCycleLength: averageCycleLength,
        averagePeriodLength: averagePeriodLength,
        lastPeriodStart: lastPeriodStart
    )
}

private func makeEntry(daysAgo: Int) -> CycleEntry {
    let calendar = Calendar.current
    let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return CycleEntry(periodStart: date)
}

private func makeEntriesWithGaps(_ gapsInDays: [Int]) -> [CycleEntry] {
    // gapsInDays: intervals between consecutive period starts
    // E.g. [28, 28, 28] → 3 gaps → 4 entries
    var entries: [CycleEntry] = []
    let calendar = Calendar.current
    // Anchor first period start far enough in the past
    let totalDays = gapsInDays.reduce(0, +)
    var currentDate = calendar.date(byAdding: .day, value: -(totalDays + 10), to: Date()) ?? Date()
    entries.append(CycleEntry(periodStart: currentDate))
    for gap in gapsInDays {
        currentDate = calendar.date(byAdding: .day, value: gap, to: currentDate) ?? currentDate
        entries.append(CycleEntry(periodStart: currentDate))
    }
    return entries
}

// MARK: - PredictionEngine Tests

@Suite("PredictionEngine")
struct PredictionEngineTests {
    let engine = PredictionEngine()

    // MARK: Zero cycles → uses defaults, confidence = .low

    @Test("Zero cycles uses settings defaults and returns low confidence")
    func zeroCyclesUsesDefaults() {
        let settings = makeSettings(averageCycleLength: 28)
        let result = engine.nextPeriodDate(from: [], settings: settings)

        #expect(result.confidence == .low)
        // With no cycles and no lastPeriodStart, anchor is approximately today
        // Next period should be ~28 days from now
        let calendar = Calendar.current
        let daysUntil = calendar.dateComponents([.day], from: Date(), to: result.nextPeriod).day ?? 0
        #expect(daysUntil >= 27 && daysUntil <= 29)
    }

    // MARK: One cycle → confidence = .low

    @Test("One cycle logged returns low confidence")
    func oneCycleIsLowConfidence() {
        let settings = makeSettings(averageCycleLength: 28)
        let entries = [makeEntry(daysAgo: 10)]
        let result = engine.nextPeriodDate(from: entries, settings: settings)

        #expect(result.confidence == .low)
        // Should be 28 days from the cycle start, i.e. about 18 days from now
        let calendar = Calendar.current
        let daysUntil = calendar.dateComponents([.day], from: Date(), to: result.nextPeriod).day ?? 0
        #expect(daysUntil >= 16 && daysUntil <= 20)
    }

    // MARK: Three regular 28-day cycles → high confidence, ~28 days

    @Test("Three regular 28-day cycles yields high confidence and ~28 day next period")
    func threeRegularCycles() {
        let settings = makeSettings(averageCycleLength: 28)
        // 3 gaps of exactly 28 days → 4 entries; last entry is the most recent
        let entries = makeEntriesWithGaps([28, 28, 28])
        let result = engine.nextPeriodDate(from: entries, settings: settings)

        #expect(result.confidence == .high)

        // The next period should be 28 days from the last cycle start
        guard let lastEntry = entries.sorted(by: { $0.periodStart < $1.periodStart }).last else {
            Issue.record("Expected entries to be non-empty")
            return
        }
        let calendar = Calendar.current
        let expectedNext = calendar.date(byAdding: .day, value: 28, to: lastEntry.periodStart) ?? lastEntry.periodStart
        let diff = abs(result.nextPeriod.timeIntervalSince(expectedNext))
        // Allow ≤ 1 day tolerance for rounding
        #expect(diff < 86400)
    }

    // MARK: Irregular cycles (variance > 5 days) → medium confidence

    @Test("Irregular cycles with high variance return medium confidence")
    func irregularCyclesAreMediumConfidence() {
        let settings = makeSettings(averageCycleLength: 28)
        // Gaps: 22, 35, 24, 38 → variance well above 9 (SD > 3), but SD ≤ 5 borderline;
        // use very irregular to ensure medium (not high)
        // Mean = (22+35+24+38)/4 = 29.75, variance = large → should be .medium or .low
        // Variance: diffs squared: (22-29.75)^2=60.06, (35-29.75)^2=27.56, (24-29.75)^2=33.06, (38-29.75)^2=68.06
        // Mean variance ≈ 47.2 > 25 → actually .low
        // Use gaps with variance > 9 but <= 25 for .medium: e.g. 25, 31, 27, 33
        // Mean = 29, diffs: -4, 2, -2, 4, squared: 16,4,4,16 → mean variance = 10 > 9 → .medium
        let entries = makeEntriesWithGaps([25, 31, 27, 33])
        let result = engine.nextPeriodDate(from: entries, settings: settings)

        #expect(result.confidence == .medium)
    }

    // MARK: Fertile window is 5 days ending ~14 days before next period

    @Test("Fertile window spans 5 days ending on ovulation day (14 days before next period)")
    func fertileWindowSpansFiveDays() {
        let nextPeriod = Calendar.current.date(byAdding: .day, value: 28, to: Date()) ?? Date()
        let window = engine.fertileWindow(nextPeriod: nextPeriod, averageCycleLength: 28)

        // Duration should be 5 days
        let durationInDays = window.duration / (24 * 60 * 60)
        #expect(abs(durationInDays - 5.0) < 0.01)

        // Window should end on ovulation day (14 days before next period)
        let ovulation = engine.ovulationDate(nextPeriod: nextPeriod, averageCycleLength: 28)
        // Window end = ovulation day end (start + duration)
        let windowEnd = window.start.addingTimeInterval(window.duration)
        let diffToOvulationEnd = abs(windowEnd.timeIntervalSince(ovulation) - (24 * 60 * 60))
        #expect(diffToOvulationEnd < 60) // within 1 minute
    }

    // MARK: Ovulation is ~14 days before next period

    @Test("Ovulation date is exactly 14 days before next period")
    func ovulationIs14DaysBeforeNextPeriod() {
        let nextPeriod = Calendar.current.date(byAdding: .day, value: 28, to: Date()) ?? Date()
        let ovulation = engine.ovulationDate(nextPeriod: nextPeriod, averageCycleLength: 28)

        let calendar = Calendar.current
        let daysBefore = calendar.dateComponents([.day], from: ovulation, to: nextPeriod).day ?? 0
        #expect(daysBefore == 14)
    }

    // MARK: Fertile window ends on ovulation day (integrated)

    @Test("Fertile window end is the ovulation day")
    func fertileWindowEndsOnOvulation() {
        let settings = makeSettings(averageCycleLength: 28)
        let entries = makeEntriesWithGaps([28, 28, 28])
        let result = engine.nextPeriodDate(from: entries, settings: settings)

        let ovulation = engine.ovulationDate(
            nextPeriod: result.nextPeriod,
            averageCycleLength: 28
        )

        // The fertile window's end should be the day after ovulation starts (window includes ovulation day)
        let windowEndDay = Calendar.current.startOfDay(
            for: result.fertileWindow.start.addingTimeInterval(result.fertileWindow.duration - 1)
        )
        let ovulationDay = Calendar.current.startOfDay(for: ovulation)
        #expect(windowEndDay == ovulationDay)
    }

    // MARK: daysUntilNextPeriod is non-negative

    @Test("daysUntilNextPeriod is always non-negative")
    func daysUntilNeverNegative() {
        let settings = makeSettings(averageCycleLength: 28)
        // Use a cycle start far in the past to make next period in the past too
        let pastEntry = CycleEntry(
            periodStart: Calendar.current.date(byAdding: .day, value: -200, to: Date()) ?? Date()
        )
        let result = engine.nextPeriodDate(from: [pastEntry], settings: settings)
        #expect(result.daysUntilNextPeriod >= 0)
    }
}
