import WidgetKit
import SwiftUI

// MARK: - App Group Suite Name

private let appGroupSuiteName = "group.app.solstice.ios"
private let nextPeriodKey = "nextPeriodDate"
private let daysUntilKey = "daysUntilNextPeriod"

// MARK: - Timeline Entry

struct SolsticeWidgetEntry: TimelineEntry {
    let date: Date
    let daysUntilNextPeriod: Int
    let nextPeriodDate: Date?
}

// MARK: - Timeline Provider

struct SolsticeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SolsticeWidgetEntry {
        SolsticeWidgetEntry(date: Date(), daysUntilNextPeriod: 12, nextPeriodDate: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SolsticeWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SolsticeWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh at midnight each day
        let nextMidnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func currentEntry() -> SolsticeWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupSuiteName)
        let daysUntil = defaults?.integer(forKey: daysUntilKey) ?? -1
        let nextPeriod = defaults?.object(forKey: nextPeriodKey) as? Date
        return SolsticeWidgetEntry(
            date: Date(),
            daysUntilNextPeriod: daysUntil,
            nextPeriodDate: nextPeriod
        )
    }
}

// MARK: - Widget Entry View

struct SolsticeWidgetEntryView: View {
    var entry: SolsticeWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            Color(red: 194/255, green: 97/255, blue: 61/255) // solsticeAccent
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Solstice")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if entry.daysUntilNextPeriod < 0 {
                    Text("Set up Solstice")
                        .font(family == .systemSmall ? .headline : .title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else if entry.daysUntilNextPeriod == 0 {
                    Text("Period")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Today")
                        .font(family == .systemSmall ? .title2 : .title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text("Next period in")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(entry.daysUntilNextPeriod)")
                            .font(family == .systemSmall ? .largeTitle : .system(size: 48, weight: .bold, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("days")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                if family == .systemMedium, let nextPeriod = entry.nextPeriodDate, entry.daysUntilNextPeriod > 0 {
                    Text(nextPeriod, style: .date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if entry.daysUntilNextPeriod < 0 {
            return "Solstice widget. Open Solstice to set up."
        } else if entry.daysUntilNextPeriod == 0 {
            return "Solstice widget. Period today."
        } else {
            return "Solstice widget. \(entry.daysUntilNextPeriod) days until next period."
        }
    }
}

// MARK: - Widget Configuration

@main
struct SolsticeWidget: Widget {
    let kind = "SolsticeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SolsticeWidgetProvider()) { entry in
            SolsticeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Period")
        .description("Shows days until your next predicted period.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
