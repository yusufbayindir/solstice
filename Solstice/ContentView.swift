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
                    InsightsPlaceholderView()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsPlaceholderView()
                }
            }
        }
        .tint(.solsticeAccent)
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.solsticeBackground.ignoresSafeArea()
            Text("Home")
                .font(.title)
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .navigationTitle("Solstice")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CalendarPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.solsticeBackground.ignoresSafeArea()
            Text("Calendar")
                .font(.title)
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .navigationTitle("Calendar")
    }
}

struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.solsticeBackground.ignoresSafeArea()
            Text("Insights")
                .font(.title)
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .navigationTitle("Insights")
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.solsticeBackground.ignoresSafeArea()
            Text("Settings")
                .font(.title)
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .navigationTitle("Settings")
    }
}
