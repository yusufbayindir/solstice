import Foundation

// MARK: - Supporting Types

enum PredictionConfidence: String, Sendable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high: return "High confidence"
        case .medium: return "Moderate estimate"
        case .low: return "Early estimate"
        }
    }
}

struct PredictionResult: Sendable {
    let nextPeriod: Date
    let confidence: PredictionConfidence
    let fertileWindow: DateInterval
    let ovulationDate: Date
    let daysUntilNextPeriod: Int
}

// MARK: - PredictionEngine

/// A pure, side-effect-free value type that computes on-device cycle predictions.
/// All computation is based solely on the provided cycle history and settings;
/// no network calls, no storage access, no global state.
struct PredictionEngine: Sendable {

    // MARK: - Public API

    /// Compute the next period date and related predictions from logged cycle history.
    ///
    /// - Parameters:
    ///   - cycles: All logged CycleEntry records, in any order.
    ///   - settings: User's AppSettings providing defaults when history is sparse.
    /// - Returns: A PredictionResult with next period, fertile window, ovulation, and confidence.
    func nextPeriodDate(from cycles: [CycleEntry], settings: AppSettings) -> PredictionResult {
        let sortedCycles = cycles.sorted { $0.periodStart < $1.periodStart }
        let averageCycleLength: Double
        let confidence: PredictionConfidence

        if sortedCycles.count < 2 {
            // Fewer than 2 cycles: fall back to settings defaults
            averageCycleLength = Double(settings.averageCycleLength)
            confidence = .low
        } else {
            // Compute rolling average of last 3–6 cycles (using inter-cycle start gaps)
            let gaps = computeCycleGaps(from: sortedCycles)
            let windowGaps = Array(gaps.suffix(6))

            let average = windowGaps.reduce(0.0, +) / Double(windowGaps.count)
            let variance = computeVariance(values: windowGaps, mean: average)

            averageCycleLength = average

            // Confidence is based on variance and number of data points
            if windowGaps.count >= 3 && variance <= 9.0 {
                // Standard deviation ≤ 3 days and at least 3 cycles
                confidence = .high
            } else if variance <= 25.0 {
                // Standard deviation ≤ 5 days
                confidence = .medium
            } else {
                confidence = .low
            }
        }

        // Compute next period date from the most recent cycle start
        guard let lastCycle = sortedCycles.last else {
            // No cycles at all: use settings.lastPeriodStart or today as anchor
            let anchor = settings.lastPeriodStart ?? Date()
            return buildResult(
                anchor: anchor,
                averageCycleLength: Double(settings.averageCycleLength),
                confidence: .low
            )
        }

        return buildResult(
            anchor: lastCycle.periodStart,
            averageCycleLength: averageCycleLength,
            confidence: confidence
        )
    }

    /// Compute the fertile window (typically 5 days ending ~14 days before next period).
    ///
    /// The fertile window spans roughly 5 days ending on ovulation day (which is
    /// approximately cycle-length minus 14 days from last period start, i.e. 14 days before
    /// the next period).
    ///
    /// - Parameters:
    ///   - nextPeriod: The predicted next period start date.
    ///   - averageCycleLength: The user's average cycle length in days.
    /// - Returns: A DateInterval representing the fertile window.
    func fertileWindow(nextPeriod: Date, averageCycleLength: Int) -> DateInterval {
        let ovulation = ovulationDate(nextPeriod: nextPeriod, averageCycleLength: averageCycleLength)
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -4, to: ovulation) ?? ovulation
        // Fertile window: 5 days (4 days before ovulation + ovulation day)
        let duration: TimeInterval = 5 * 24 * 60 * 60
        return DateInterval(start: windowStart, duration: duration)
    }

    /// Compute the predicted ovulation date (~14 days before the next period).
    ///
    /// Ovulation typically occurs 14 days before the next period, regardless of cycle length.
    /// This is the luteal phase length assumption (Naegele's rule approximation).
    ///
    /// - Parameters:
    ///   - nextPeriod: The predicted next period start date.
    ///   - averageCycleLength: The user's average cycle length in days (used for context,
    ///     but the 14-day luteal phase is the governing factor here).
    /// - Returns: The predicted ovulation date.
    func ovulationDate(nextPeriod: Date, averageCycleLength: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -14, to: nextPeriod) ?? nextPeriod
    }

    // MARK: - Private Helpers

    private func computeCycleGaps(from sortedCycles: [CycleEntry]) -> [Double] {
        guard sortedCycles.count >= 2 else { return [] }
        var gaps: [Double] = []
        for index in 1 ..< sortedCycles.count {
            let gap = sortedCycles[index].periodStart.timeIntervalSince(sortedCycles[index - 1].periodStart)
            let gapInDays = gap / (24 * 60 * 60)
            // Only include plausible cycle lengths (15–60 days) to filter data entry errors
            if gapInDays >= 15 && gapInDays <= 60 {
                gaps.append(gapInDays)
            }
        }
        return gaps
    }

    private func computeVariance(values: [Double], mean: Double) -> Double {
        guard values.count > 1 else { return 0.0 }
        let sumSquaredDiffs = values.reduce(0.0) { accumulator, value in
            let diff = value - mean
            return accumulator + diff * diff
        }
        return sumSquaredDiffs / Double(values.count)
    }

    private func buildResult(
        anchor: Date,
        averageCycleLength: Double,
        confidence: PredictionConfidence
    ) -> PredictionResult {
        let calendar = Calendar.current
        let cycleDays = Int(averageCycleLength.rounded())
        let nextPeriod = calendar.date(byAdding: .day, value: cycleDays, to: anchor) ?? anchor

        let now = Date()
        let rawDaysUntil = calendar.dateComponents([.day], from: now, to: nextPeriod).day ?? 0
        let daysUntil = max(0, rawDaysUntil)

        let fertile = fertileWindow(nextPeriod: nextPeriod, averageCycleLength: cycleDays)
        let ovulation = ovulationDate(nextPeriod: nextPeriod, averageCycleLength: cycleDays)

        return PredictionResult(
            nextPeriod: nextPeriod,
            confidence: confidence,
            fertileWindow: fertile,
            ovulationDate: ovulation,
            daysUntilNextPeriod: daysUntil
        )
    }
}
