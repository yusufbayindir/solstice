import SwiftUI
import Observation

enum AppTab: Int, CaseIterable {
    case home
    case calendar
    case insights
    case settings
}

@MainActor
@Observable
final class AppState {
    var selectedTab: AppTab = .home
    var showLogEntry: Bool = false
    var appLocked: Bool = false
    var colorSchemePreference: ColorScheme? = nil
}
