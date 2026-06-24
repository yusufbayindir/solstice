import SwiftUI
import SwiftData

// MARK: - DayDetailSheet

struct DayDetailSheet: View {

    let date: Date
    let cycles: [CycleEntry]
    let prediction: PredictionResult?
    let onLog: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Derived state

    private var cal: Calendar { Calendar.current }

    private var matchingEntry: CycleEntry? {
        cycles.first { entry in
            if let end = entry.periodEnd {
                return date >= cal.startOfDay(for: entry.periodStart)
                    && date <= cal.startOfDay(for: end)
            }
            return cal.isDate(date, inSameDayAs: entry.periodStart)
        }
    }

    private var symptoms: [SymptomLog] {
        guard let entry = matchingEntry else { return [] }
        return entry.symptomLogs.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    private var moods: [MoodLog] {
        guard let entry = matchingEntry else { return [] }
        return entry.moodLogs.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    private var phaseLabel: String? {
        guard let pred = prediction else { return nil }

        if let entry = matchingEntry {
            if let end = entry.periodEnd {
                let dayNum = (cal.dateComponents([.day], from: entry.periodStart, to: date).day ?? 0) + 1
                if date >= cal.startOfDay(for: entry.periodStart) && date <= cal.startOfDay(for: end) {
                    return "Period — Day \(dayNum)"
                }
            } else if cal.isDate(date, inSameDayAs: entry.periodStart) {
                return "Period — Day 1"
            }
        }

        if cal.isDate(date, inSameDayAs: pred.ovulationDate) {
            return "Ovulation"
        }
        let fertileStart = cal.startOfDay(for: pred.fertileWindow.start)
        let fertileEnd = cal.startOfDay(for: pred.fertileWindow.end)
        let dayStart = cal.startOfDay(for: date)
        if dayStart >= fertileStart && dayStart <= fertileEnd {
            return "Fertile window"
        }
        return nil
    }

    private var cycleDay: Int? {
        guard let lastCycle = cycles.sorted(by: { $0.periodStart < $1.periodStart }).last else {
            return nil
        }
        let days = cal.dateComponents([.day], from: lastCycle.periodStart, to: date).day ?? 0
        let day = days + 1
        return day > 0 ? day : nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    Divider()

                    // Phase label
                    if let phase = phaseLabel {
                        phaseSection(phase)
                        Divider()
                    }

                    // Logged data
                    loggedDataSection

                    Spacer(minLength: 16)
                }
                .padding(16)
            }
            .background(Color.solsticeBackground)
            .navigationTitle(date.formatted(.dateTime.weekday(.wide).month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.solsticeAccent)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .safeAreaInset(edge: .bottom) {
                logButton
                    .padding(16)
                    .background(.thinMaterial)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date, style: .date)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                if let day = cycleDay {
                    Text("Cycle day \(day)")
                        .font(.subheadline)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
            }
            Spacer()

            if Calendar.current.isDateInToday(date) {
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.solsticeAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.solsticeAccentSoft)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Phase Section

    private func phaseSection(_ phase: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: phaseSymbol(phase))
                .font(.system(size: 18))
                .foregroundStyle(phaseColor(phase))
                .accessibilityHidden(true)

            Text(phase)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase: \(phase)")
    }

    // MARK: - Logged Data

    private var loggedDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if symptoms.isEmpty && moods.isEmpty {
                Text("Nothing logged for this day.")
                    .font(.callout)
                    .foregroundStyle(Color.solsticeTextSecondary)
            } else {
                if !symptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Symptoms")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.solsticeTextSecondary)
                            .textCase(.uppercase)

                        FlowLayout(spacing: 8) {
                            ForEach(symptoms, id: \.symptom) { log in
                                Text(log.symptom.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.solsticeTextPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.solsticeSurfaceSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if !moods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.solsticeTextSecondary)
                            .textCase(.uppercase)

                        FlowLayout(spacing: 8) {
                            ForEach(moods, id: \.mood) { log in
                                Text(log.mood.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.solsticeTextPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.solsticeSurfaceSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button {
            dismiss()
            onLog(date)
        } label: {
            Text(matchingEntry != nil ? "Edit log for this day" : "Log for this day")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.solsticeAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel(matchingEntry != nil ? "Edit log for this day" : "Log for this day")
    }

    // MARK: - Helpers

    private func phaseSymbol(_ phase: String) -> String {
        if phase.hasPrefix("Period") { return "drop.fill" }
        if phase == "Ovulation" { return "sparkle" }
        if phase == "Fertile window" { return "leaf.fill" }
        return "calendar"
    }

    private func phaseColor(_ phase: String) -> Color {
        if phase.hasPrefix("Period") { return .solsticePeriod }
        if phase == "Ovulation" { return .solsticeOvulation }
        if phase == "Fertile window" { return .solsticeFertile }
        return .solsticeTextSecondary
    }
}

// MARK: - FlowLayout (wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
