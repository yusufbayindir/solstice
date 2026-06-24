import SwiftUI

// MARK: - HomeTab

/// Thin wrapper that owns the NavigationStack for the Home tab
/// and presents LogEntryView as a sheet when appState.showLogEntry is true.
struct HomeTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            HomeDashboardView()
        }
        .sheet(isPresented: $appState.showLogEntry) {
            LogEntryView(initialDate: Date())
        }
    }
}
