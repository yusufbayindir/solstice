import SwiftUI
import SwiftData

// MARK: - FlowLevel

enum FlowLevel: Int, CaseIterable, Sendable {
    case none, light, medium, heavy

    var displayName: String {
        switch self {
        case .none: return "None"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }

    var symbol: String {
        switch self {
        case .none: return "minus"
        case .light: return "drop"
        case .medium: return "drop.halffull"
        case .heavy: return "drop.fill"
        }
    }
}

// MARK: - LogEntryView

struct LogEntryView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    var initialDate: Date
    var existingEntry: CycleEntry? = nil

    @State private var selectedDate: Date
    @State private var periodStart: Date?
    @State private var periodEnd: Date?
    @State private var flowLevel: FlowLevel = .none
    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var selectedMoods: Set<Mood> = []
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showValidationError: Bool = false

    private let maxNoteLength = 280

    // MARK: - Init

    init(initialDate: Date, existingEntry: CycleEntry? = nil) {
        self.initialDate = initialDate
        self.existingEntry = existingEntry
        _selectedDate = State(initialValue: initialDate)

        if let entry = existingEntry {
            _periodStart = State(initialValue: entry.periodStart)
            _periodEnd = State(initialValue: entry.periodEnd)
            _notes = State(initialValue: entry.notes)
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        if let start = periodStart, let end = periodEnd {
            return end >= start
        }
        return true
    }

    private var hasChanges: Bool {
        periodStart != nil || !selectedSymptoms.isEmpty || !selectedMoods.isEmpty || !notes.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    periodSection
                        .padding(.bottom, 20)

                    if periodStart != nil {
                        flowSection
                            .padding(.bottom, 20)
                    }

                    symptomsSection
                        .padding(.bottom, 20)

                    moodSection
                        .padding(.bottom, 20)

                    notesSection
                        .padding(.bottom, 20)

                    privacyBadge
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.solsticeBackground)
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.solsticeAccent)
                    .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(canSave ? Color.solsticeAccent : Color.solsticeTextTertiary)
                    .disabled(!canSave || isSaving)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Period Section

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Period", symbol: "drop.fill")

            VStack(spacing: 0) {
                // Period Start
                HStack {
                    Text("Period start")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Spacer()
                    DatePicker(
                        "Period start",
                        selection: Binding(
                            get: { periodStart ?? selectedDate },
                            set: { periodStart = $0 }
                        ),
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(Color.solsticeAccent)
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        if periodStart == nil { periodStart = selectedDate }
                    })
                }
                .padding(16)
                .frame(minHeight: 44)

                if periodStart != nil {
                    Divider().padding(.leading, 16)

                    // Period End (optional)
                    HStack {
                        Text("Period end")
                            .font(.body)
                            .foregroundStyle(Color.solsticeTextPrimary)
                        Spacer()

                        if let start = periodStart {
                            DatePicker(
                                "Period end",
                                selection: Binding(
                                    get: { periodEnd ?? start },
                                    set: { periodEnd = $0 }
                                ),
                                in: start...Date(),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .tint(Color.solsticeAccent)
                        }

                        if periodEnd != nil {
                            Button {
                                periodEnd = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.solsticeTextTertiary)
                            }
                            .frame(width: 44, height: 44)
                            .accessibilityLabel("Clear period end date")
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.vertical, 4)
                    .frame(minHeight: 44)
                }
            }
            .background(Color.solsticeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if periodStart == nil {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86)) {
                        periodStart = selectedDate
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Label("Log period start", systemImage: "drop.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.solsticeAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityLabel("Log period start")
            }
        }
    }

    // MARK: - Flow Section

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Flow", symbol: "drop.halffull")

            HStack(spacing: 0) {
                ForEach(FlowLevel.allCases, id: \.self) { level in
                    flowButton(level)
                }
            }
            .padding(8)
            .background(Color.solsticeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func flowButton(_ level: FlowLevel) -> some View {
        let isSelected = flowLevel == level
        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.18)) {
                flowLevel = level
            }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: level.symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : Color.solsticePeriod)
                Text(level.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : Color.solsticeTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Color.solsticePeriod : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("\(level.displayName) flow\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Symptoms Section

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Symptoms", symbol: "bolt.heart")

            chipGrid(
                items: Symptom.allCases,
                label: { $0.displayName },
                symbol: symptomSymbol,
                isSelected: { selectedSymptoms.contains($0) },
                toggle: { symptom in
                    toggleItem(symptom, in: &selectedSymptoms)
                }
            )
        }
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Mood", symbol: "face.smiling")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        chipButton(
                            label: mood.displayName,
                            symbol: moodSymbol(mood),
                            isSelected: selectedMoods.contains(mood)
                        ) {
                            toggleItem(mood, in: &selectedMoods)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Note", symbol: "pencil")

            VStack(alignment: .trailing, spacing: 4) {
                TextEditor(text: $notes)
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.solsticeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        if notes.isEmpty {
                            Text("Add a note (optional)…")
                                .font(.body)
                                .foregroundStyle(Color.solsticeTextTertiary)
                                .padding(16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: notes) { _, newValue in
                        if newValue.count > maxNoteLength {
                            notes = String(newValue.prefix(maxNoteLength))
                        }
                    }

                Text("\(notes.count) / \(maxNoteLength)")
                    .font(.caption2)
                    .foregroundStyle(notes.count >= maxNoteLength ? Color.solsticeWarning : Color.solsticeTextTertiary)
            }
        }
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

    // MARK: - Generic Chip Grid

    private func chipGrid<T: Hashable>(
        items: [T],
        label: @escaping (T) -> String,
        symbol: @escaping (T) -> String,
        isSelected: @escaping (T) -> Bool,
        toggle: @escaping (T) -> Void
    ) -> some View {
        let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { item in
                chipButton(
                    label: label(item),
                    symbol: symbol(item),
                    isSelected: isSelected(item)
                ) {
                    toggle(item)
                }
            }
        }
    }

    private func chipButton(label: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.18)) {
                action()
            }
            UISelectionFeedbackGenerator().selectionChanged()
        }) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 13))
                    .accessibilityHidden(true)
                Text(label)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.solsticeAccent : Color.solsticeTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(isSelected ? Color.solsticeAccentSoft : Color.solsticeSurface)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.solsticeAccent : Color.solsticeSeparator, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .accessibilityLabel("\(label)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(Color.solsticeAccent)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Toggle Helpers

    private func toggleItem<T: Hashable>(_ item: T, in set: inout Set<T>) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }

    // MARK: - Symbol Helpers

    private func symptomSymbol(_ symptom: Symptom) -> String {
        switch symptom {
        case .cramps: return "bolt.heart"
        case .headache: return "bandage"
        case .bloating: return "circle.dashed"
        case .fatigue: return "zzz"
        case .backache: return "figure.walk"
        case .breastTenderness: return "heart"
        case .nausea: return "wind"
        case .spotting: return "drop"
        }
    }

    private func moodSymbol(_ mood: Mood) -> String {
        switch mood {
        case .happy: return "sun.max"
        case .calm: return "face.smiling"
        case .anxious: return "wind"
        case .sad: return "cloud.rain"
        case .irritable: return "bolt"
        case .energetic: return "sparkles"
        case .tired: return "moon"
        }
    }

    // MARK: - Save

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        // Enforce periodEnd >= periodStart on all paths (create and update)
        let resolvedStart = periodStart ?? selectedDate
        let resolvedEnd: Date? = periodEnd.flatMap { $0 >= resolvedStart ? $0 : nil }

        let entry: CycleEntry
        if let existing = existingEntry {
            // Update existing entry
            existing.periodStart = resolvedStart
            existing.periodEnd = resolvedEnd
            existing.notes = notes
            entry = existing
        } else {
            // Create new entry
            let newEntry = CycleEntry(
                periodStart: resolvedStart,
                periodEnd: resolvedEnd,
                notes: notes
            )
            modelContext.insert(newEntry)
            entry = newEntry
        }

        // Remove old symptom/mood logs
        for log in entry.symptomLogs { modelContext.delete(log) }
        for log in entry.moodLogs { modelContext.delete(log) }
        entry.symptomLogs = []
        entry.moodLogs = []

        // Insert symptom logs
        for symptom in selectedSymptoms {
            let log = SymptomLog(date: resolvedStart, symptom: symptom, intensity: 1)
            modelContext.insert(log)
            entry.symptomLogs.append(log)
        }

        // Insert mood logs
        for mood in selectedMoods {
            let log = MoodLog(date: resolvedStart, mood: mood)
            modelContext.insert(log)
            entry.moodLogs.append(log)
        }

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            // Roll back all in-memory inserts so a retry doesn't duplicate records
            modelContext.rollback()
            isSaving = false
        }
    }
}
