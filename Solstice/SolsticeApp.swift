import SwiftUI
import SwiftData

@main
struct SolsticeApp: App {
    @State private var appState = AppState()
    private let predictionEngine = PredictionEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.predictionEngine, predictionEngine)
                .preferredColorScheme(appState.colorSchemePreference)
        }
        .modelContainer(for: [
            CycleEntry.self,
            SymptomLog.self,
            MoodLog.self,
            AppSettings.self
        ])
    }
}

// MARK: - PredictionEngine Environment Key

struct PredictionEngineKey: EnvironmentKey {
    static let defaultValue = PredictionEngine()
}

extension EnvironmentValues {
    var predictionEngine: PredictionEngine {
        get { self[PredictionEngineKey.self] }
        set { self[PredictionEngineKey.self] = newValue }
    }
}
