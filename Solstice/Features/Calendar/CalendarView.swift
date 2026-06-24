import SwiftUI
import SwiftData

// MARK: - CalendarView

struct CalendarView: View {

    // MARK: - Data

    @Query(sort: \CycleEntry.periodStart, order: .reverse)
    private var cycles: [CycleEntry]

    @Query private var settingsArray: [AppSettings]

    @Environment(\.predictionEngine) private var predictionEngine
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: AppSettings? { settingsArray.first }

    // MARK: - State

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date? = nil
    @State private var showDayDetail: Bool = false
    @State private var showLogEntry: Bool = false
    @State private var logDate: Date = Date()

    // MARK: - Prediction

    private var prediction: PredictionResult? {
        guard let settings else { return nil }
        return predictionEngine.nextPeriodDate(from: cycles, settings: settings)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                weekdayHeaderRow
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)

                Divider()

                monthGridScrollView
            }
            .background(Color.solsticeBackground)

            // Legend bar (pinned bottom)
            VStack(spacing: 0) {
                Spacer()
                legendBar
            }
            .ignoresSafeArea(edges: .bottom)

            // FAB
            fabButton
                .padding(.trailing, 20)
                .padding(.bottom, 100) // above legend
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !Calendar.current.isDate(displayedMonth, equalTo: Calendar.current.startOfMonth(for: Date()), toGranularity: .month) {
                    Button("Today") {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86)) {
                            displayedMonth = Calendar.current.startOfMonth(for: Date())
                        }
                    }
                    .foregroundStyle(Color.solsticeAccent)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
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
        .sheet(item: Binding(
            get: { selectedDate.map { SelectedDay(date: $0) } },
            set: { newVal in selectedDate = newVal?.date }
        )) { selectedDay in
            DayDetailSheet(
                date: selectedDay.date,
                cycles: cycles,
                prediction: prediction,
                onLog: { date in
                    logDate = date
                    showLogEntry = true
                }
            )
        }
        .sheet(isPresented: $showLogEntry) {
            LogEntryView(initialDate: logDate)
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeaderRow: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Month Grid Scroll

    private var monthGridScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // Show previous month, current month, and 3 forecast months
                    ForEach(monthsToDisplay(), id: \.self) { monthStart in
                        monthSection(monthStart)
                            .id(monthStart)
                    }
                }
                .padding(.bottom, 120) // legend bar clearance
            }
            .onAppear {
                proxy.scrollTo(displayedMonth, anchor: .top)
            }
            .onChange(of: displayedMonth) { _, newMonth in
                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86)) {
                    proxy.scrollTo(newMonth, anchor: .top)
                }
            }
        }
    }

    // MARK: - Month Section

    private func monthSection(_ monthStart: Date) -> some View {
        VStack(spacing: 0) {
            // Month header with nav chevrons
            HStack {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86)) {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.solsticeAccent)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Previous month")
                .opacity(Calendar.current.isDate(monthStart, equalTo: displayedMonth, toGranularity: .month) ? 1 : 0)
                .disabled(!Calendar.current.isDate(monthStart, equalTo: displayedMonth, toGranularity: .month))

                Spacer()

                Text(monthStart, format: .dateTime.month(.wide).year())
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86)) {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.solsticeAccent)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Next month")
                .opacity(Calendar.current.isDate(monthStart, equalTo: displayedMonth, toGranularity: .month) ? 1 : 0)
                .disabled(!Calendar.current.isDate(monthStart, equalTo: displayedMonth, toGranularity: .month))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            monthGrid(monthStart)
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Month Grid

    private func monthGrid(_ monthStart: Date) -> some View {
        let days = daysInMonthGrid(for: monthStart)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { day in
                if let day {
                    CalendarDayCell(
                        date: day,
                        isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false,
                        dayState: dayState(for: day),
                        onTap: {
                            selectedDate = day
                        }
                    )
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    // MARK: - Day State

    private func dayState(for date: Date) -> CalendarDayState {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)

        // Check logged entries
        var isLoggedPeriod = false
        var hasSymptomOrMood = false

        for cycle in cycles {
            if let end = cycle.periodEnd {
                if date >= cal.startOfDay(for: cycle.periodStart) && date <= cal.startOfDay(for: end) {
                    isLoggedPeriod = true
                }
            } else if cal.isDate(date, inSameDayAs: cycle.periodStart) {
                isLoggedPeriod = true
            }
            if !cycle.symptomLogs.filter({ cal.isDate($0.date, inSameDayAs: date) }).isEmpty
                || !cycle.moodLogs.filter({ cal.isDate($0.date, inSameDayAs: date) }).isEmpty {
                hasSymptomOrMood = true
            }
        }

        // Predicted states
        var isPredictedPeriod = false
        var isFertile = false
        var isOvulation = false

        if let pred = prediction {
            let nextPeriodStart = cal.startOfDay(for: pred.nextPeriod)
            let settings = settings
            let periodDays = settings?.averagePeriodLength ?? 5
            if let periodEnd = cal.date(byAdding: .day, value: periodDays - 1, to: nextPeriodStart) {
                let dayStart = cal.startOfDay(for: date)
                if !isLoggedPeriod && dayStart >= nextPeriodStart && dayStart <= cal.startOfDay(for: periodEnd) {
                    isPredictedPeriod = true
                }
            }

            let fertileStart = cal.startOfDay(for: pred.fertileWindow.start)
            let fertileEnd = cal.startOfDay(for: pred.fertileWindow.end)
            let dayStart = cal.startOfDay(for: date)
            if dayStart >= fertileStart && dayStart <= fertileEnd {
                isFertile = true
            }

            if cal.isDate(date, inSameDayAs: pred.ovulationDate) {
                isOvulation = true
            }
        }

        return CalendarDayState(
            isToday: isToday,
            isLoggedPeriod: isLoggedPeriod,
            isPredictedPeriod: isPredictedPeriod,
            isFertile: isFertile,
            isOvulation: isOvulation,
            hasSymptomOrMood: hasSymptomOrMood
        )
    }

    // MARK: - Month Helpers

    private func monthsToDisplay() -> [Date] {
        let cal = Calendar.current
        var months: [Date] = []
        // 1 month back + current + 3 forward
        for offset in -1...3 {
            if let month = cal.date(byAdding: .month, value: offset, to: Calendar.current.startOfMonth(for: Date())) {
                months.append(month)
            }
        }
        return months
    }

    private func daysInMonthGrid(for monthStart: Date) -> [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leadingBlanks = firstWeekday - cal.firstWeekday

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks < 0 ? leadingBlanks + 7 : leadingBlanks)
        for day in range {
            if let date = cal.date(bySetting: .day, value: day, of: monthStart) {
                days.append(date)
            }
        }
        // Pad to multiple of 7
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    // MARK: - Legend Bar

    private var legendBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                legendItem(symbol: "circle.fill", color: .solsticePeriod, label: "Period")
                legendItem(symbol: "circle.lefthalf.filled", color: .solsticeFertile, label: "Fertile")
                legendItem(symbol: "diamond.fill", color: .solsticeOvulation, label: "Ovulation")
                legendItem(symbol: "circle", color: .solsticeAccent, label: "Today")
                legendDashedItem(color: .solsticePredicted, label: "Predicted")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend: Period, Fertile window, Ovulation, Today, Predicted")
    }

    private func legendItem(symbol: String, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
    }

    private func legendDashedItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            logDate = Date()
            showLogEntry = true
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
}

// MARK: - Calendar Day State

struct CalendarDayState {
    let isToday: Bool
    let isLoggedPeriod: Bool
    let isPredictedPeriod: Bool
    let isFertile: Bool
    let isOvulation: Bool
    let hasSymptomOrMood: Bool
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let dayState: CalendarDayState
    let onTap: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    private var increaseContrast: Bool { colorSchemeContrast == .increased }

    private var isOutOfMonth: Bool { false } // handled by nil in grid

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private var accessibilityLabel: String {
        var parts: [String] = [date.formatted(.dateTime.weekday(.wide).month().day())]
        if dayState.isToday { parts.append("Today") }
        if dayState.isLoggedPeriod { parts.append("period logged") }
        if dayState.isPredictedPeriod { parts.append("predicted period") }
        if dayState.isFertile { parts.append("fertile window") }
        if dayState.isOvulation { parts.append("ovulation") }
        if dayState.hasSymptomOrMood { parts.append("symptoms or mood logged") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background wash
                cellBackground

                // Day number
                VStack(spacing: 2) {
                    Text("\(dayNumber)")
                        .font(.body)
                        .fontWeight(dayState.isToday ? .semibold : .regular)
                        .foregroundStyle(
                            isSelected ? .white
                            : dayState.isToday ? Color.solsticeAccent
                            : Color.solsticeTextPrimary
                        )

                    // Data dot
                    if dayState.hasSymptomOrMood && !isSelected {
                        Circle()
                            .fill(Color.solsticeTextSecondary)
                            .frame(width: 4, height: 4)
                            .accessibilityHidden(true)
                    }

                    // Ovulation diamond
                    if dayState.isOvulation && !isSelected {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Color.solsticeOvulation)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(dayState.isToday ? [.isButton] : .isButton)
    }

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            Circle()
                .fill(Color.solsticeAccent)
                .frame(width: 36, height: 36)
        } else if dayState.isLoggedPeriod {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.solsticePeriodSoft)
                .frame(width: 36, height: 40)
                .overlay(
                    Circle()
                        .fill(Color.solsticePeriod)
                        .frame(width: 5, height: 5)
                        .offset(y: 12),
                    alignment: .bottom
                )
        } else if dayState.isPredictedPeriod {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    Color.solsticePeriod,
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                )
                .frame(width: 36, height: 40)
        } else if dayState.isFertile {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.solsticeFertileSoft)
                .frame(width: 36, height: 40)
        } else if dayState.isToday {
            Circle()
                .stroke(Color.solsticeAccent, lineWidth: 1.5)
                .frame(width: 36, height: 36)
        } else {
            Color.clear
                .frame(width: 36, height: 40)
        }
    }
}

// MARK: - Selected Day Wrapper (for sheet binding)

struct SelectedDay: Identifiable {
    let date: Date
    var id: Date { date }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
