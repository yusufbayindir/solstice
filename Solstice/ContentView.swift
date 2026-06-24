import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeTab()
            }
            Tab("Calendar", systemImage: "calendar", value: AppTab.calendar) {
                NavigationStack {
                    CalendarView()
                }
            }
            Tab("Insights", systemImage: "chart.xyaxis.line", value: AppTab.insights) {
                NavigationStack {
                    InsightsView()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(.solsticeAccent)
    }
}
