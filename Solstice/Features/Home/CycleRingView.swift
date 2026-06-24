import SwiftUI

// MARK: - CycleRingView

/// The hero cycle ring for the Home Dashboard.
/// Draws a 360° track representing the current cycle, with phase arcs,
/// an ovulation marker, a today knob, and center text readout.
struct CycleRingView: View {

    // MARK: - Input

    struct ViewModel: Sendable {
        /// Day within the current cycle (1-based).
        let cycleDay: Int
        /// Total predicted cycle length in days.
        let cycleLength: Int
        /// Period length in days (logged or predicted).
        let periodLength: Int
        /// Day offset of fertile window start within the cycle (0-based).
        let fertileWindowStartDay: Int
        /// Fertile window length in days.
        let fertileWindowLength: Int
        /// Day offset of ovulation within the cycle (0-based).
        let ovulationDay: Int
        /// Whether the period arc is predicted (not logged).
        let isPeriodPredicted: Bool
        /// Prediction confidence for rendering cues.
        let confidence: PredictionConfidence?
        /// Center phase label, e.g. "Period in 12 days" or "Fertile window".
        let phaseLabel: String
        /// Whether any data exists to show (false → empty template).
        let hasData: Bool
    }

    let viewModel: ViewModel
    /// Outer diameter of the ring.
    var diameter: CGFloat = 260

    // MARK: - Private

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    private var increaseContrast: Bool { colorSchemeContrast == .increased }

    private let strokeWidth: CGFloat = 18
    private let fertileStrokeWidth: CGFloat = 10

    /// Converts a cycle-day offset (0-based) to an angle on the ring.
    /// 12-o'clock (−90°) = day 1 of cycle.
    private func angle(forDayOffset day: Int) -> Angle {
        let fraction = Double(day) / Double(max(1, viewModel.cycleLength))
        return .degrees(-90 + fraction * 360)
    }

    // MARK: - Accessibility label

    private var accessibilityLabel: String {
        guard viewModel.hasData else {
            return "No cycle data. Start by logging your period."
        }
        let confidence = viewModel.confidence.map { ", \($0.displayName.lowercased())" } ?? ""
        return "Cycle day \(viewModel.cycleDay) of \(viewModel.cycleLength). \(viewModel.phaseLabel)\(confidence)."
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            ringCanvas
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel)

            legendRow
        }
    }

    // MARK: - Ring Canvas

    private var ringCanvas: some View {
        ZStack {
            if viewModel.hasData {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = (min(size.width, size.height) - strokeWidth) / 2

                    // 1. Track (base)
                    drawTrack(context: context, center: center, radius: radius)

                    // 2. Elapsed progress sweep (primary @ 30% opacity)
                    drawElapsedSweep(context: context, center: center, radius: radius)

                    // 3. Period arc
                    drawPeriodArc(context: context, center: center, radius: radius)

                    // 4. Fertile window arc (thinner, inset)
                    drawFertileArc(context: context, center: center, radius: radius)

                    // 5. Ovulation marker
                    drawOvulationMarker(context: context, center: center, radius: radius)

                    // 6. Today knob
                    drawTodayKnob(context: context, center: center, radius: radius)
                }
                .frame(width: diameter, height: diameter)
            } else {
                emptyRing
            }

            // Center text overlay
            centerText
        }
        .frame(width: diameter, height: diameter)
    }

    // MARK: - Drawing Helpers

    private func drawTrack(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        context.stroke(
            path,
            with: .color(.solsticeSeparator),
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        )
    }

    private func drawElapsedSweep(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Clamp to cycleLength so an overdue prediction doesn't wrap past 360°
        let clampedDay = min(viewModel.cycleDay - 1, viewModel.cycleLength - 1)
        let endAngle = angle(forDayOffset: max(0, clampedDay))
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: endAngle,
            clockwise: false
        )
        context.stroke(
            path,
            with: .color(Color.solsticeAccent.opacity(increaseContrast ? 0.6 : 0.30)),
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        )
    }

    private func drawPeriodArc(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        guard viewModel.periodLength > 0 else { return }
        let startAngle = Angle.degrees(-90)
        let endAngle = angle(forDayOffset: viewModel.periodLength)
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        let opacity: CGFloat = viewModel.isPeriodPredicted ? (increaseContrast ? 0.8 : 0.55) : 1.0
        if viewModel.isPeriodPredicted && !increaseContrast {
            context.stroke(
                path,
                with: .color(Color.solsticePeriod.opacity(opacity)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, dash: [8, 6])
            )
        } else {
            context.stroke(
                path,
                with: .color(Color.solsticePeriod.opacity(opacity)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )
        }
    }

    private func drawFertileArc(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        guard viewModel.fertileWindowLength > 0 else { return }
        let fertileRadius = radius - (strokeWidth - fertileStrokeWidth) / 2
        let startAngle = angle(forDayOffset: viewModel.fertileWindowStartDay)
        let endAngle = angle(forDayOffset: viewModel.fertileWindowStartDay + viewModel.fertileWindowLength)
        var path = Path()
        path.addArc(
            center: center,
            radius: fertileRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        context.stroke(
            path,
            with: .color(Color.solsticeFertile),
            style: StrokeStyle(lineWidth: fertileStrokeWidth, lineCap: .round)
        )
    }

    private func drawOvulationMarker(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let ovAngle = angle(forDayOffset: viewModel.ovulationDay)
        let radians = ovAngle.radians
        let markerCenter = CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
        let dotSize: CGFloat = 8
        let dotRect = CGRect(
            x: markerCenter.x - dotSize / 2,
            y: markerCenter.y - dotSize / 2,
            width: dotSize,
            height: dotSize
        )
        context.fill(Path(ellipseIn: dotRect), with: .color(Color.solsticeOvulation))

        // 2pt tick
        let tickLength: CGFloat = 6
        let innerPt = CGPoint(
            x: center.x + (radius - tickLength) * CGFloat(cos(radians)),
            y: center.y + (radius - tickLength) * CGFloat(sin(radians))
        )
        var tickPath = Path()
        tickPath.move(to: innerPt)
        tickPath.addLine(to: markerCenter)
        context.stroke(tickPath, with: .color(Color.solsticeOvulation), lineWidth: 2)
    }

    private func drawTodayKnob(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let clampedDay = min(viewModel.cycleDay - 1, viewModel.cycleLength - 1)
        let todayAngle = angle(forDayOffset: max(0, clampedDay))
        let radians = todayAngle.radians
        let knobCenter = CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
        let knobSize: CGFloat = 16
        let ringWidth: CGFloat = increaseContrast ? 3 : 2
        let knobRect = CGRect(
            x: knobCenter.x - knobSize / 2,
            y: knobCenter.y - knobSize / 2,
            width: knobSize,
            height: knobSize
        )
        // Filled clay circle
        context.fill(Path(ellipseIn: knobRect), with: .color(Color.solsticeAccent))
        // White inner ring
        let innerRect = CGRect(
            x: knobCenter.x - (knobSize / 2 - ringWidth),
            y: knobCenter.y - (knobSize / 2 - ringWidth),
            width: knobSize - ringWidth * 2,
            height: knobSize - ringWidth * 2
        )
        context.fill(Path(ellipseIn: innerRect), with: .color(.white))
    }

    // MARK: - Empty Ring

    private var emptyRing: some View {
        Circle()
            .stroke(Color.solsticeSeparator, lineWidth: strokeWidth)
            .frame(width: diameter - strokeWidth, height: diameter - strokeWidth)
    }

    // MARK: - Center Text

    private var centerText: some View {
        VStack(spacing: 4) {
            if viewModel.hasData {
                Text("CYCLE DAY")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeTextSecondary)

                Text("\(viewModel.cycleDay)")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .contentTransition(.numericText())

                Text(viewModel.phaseLabel)
                    .font(.callout)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
            } else {
                Image(systemName: "drop")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.solsticeTextTertiary)
                    .accessibilityHidden(true)

                Text("Start your\nfirst log")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Legend Row

    private var legendRow: some View {
        HStack(spacing: 12) {
            legendItem(color: .solsticePeriod, symbol: "circle.fill", label: "Period")
            legendItem(color: .solsticeFertile, symbol: "circle.lefthalf.filled", label: "Fertile")
            legendItem(color: .solsticeOvulation, symbol: "diamond.fill", label: "Ovulation")
            legendItem(color: .solsticeAccent, symbol: "circle.fill", label: "Today")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend: Period, Fertile window, Ovulation, Today marker")
    }

    private func legendItem(color: Color, symbol: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
    }
}
