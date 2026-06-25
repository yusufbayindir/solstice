import SwiftUI
import SwiftData

@main
struct SolsticeApp: App {
    @State private var appState = AppState()
    @State private var store = StoreManager()
    private let predictionEngine = PredictionEngine()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(appState: appState, predictionEngine: predictionEngine)
                .environment(store)
                .preferredColorScheme(appState.colorSchemePreference)
                .task {
                    await store.loadProducts()
                }
        }
        .modelContainer(for: [
            CycleEntry.self,
            SymptomLog.self,
            MoodLog.self,
            AppSettings.self
        ])
    }
}

// MARK: - RootView

/// Separates model access from the App entry point so that @Query / modelContext
/// are always available before anything is rendered.
struct RootView: View {
    let appState: AppState
    let predictionEngine: PredictionEngine

    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var lockManager: AppLockManager? = nil

    private var settings: AppSettings? { settingsArray.first }
    private var hasCompletedOnboarding: Bool { settings?.hasCompletedOnboarding ?? false }
    private var showOnboarding: Bool { !hasCompletedOnboarding }

    var body: some View {
        ZStack {
            Color.solsticeBackground.ignoresSafeArea()

            ContentView()
                .environment(appState)
                .environment(\.predictionEngine, predictionEngine)

            // App Lock overlay
            if appState.appLocked, let manager = lockManager {
                AppLockView(lockManager: manager)
                    .environment(appState)
                    .transition(
                        .opacity.animation(.snappy(duration: 0.18))
                    )
                    .zIndex(10)
            }
        }
        // Onboarding full-screen cover
        .fullScreenCover(isPresented: Binding(
            get: { showOnboarding },
            set: { _ in }   // dismissed only by completing onboarding (writing to SwiftData)
        )) {
            OnboardingView()
                .environment(appState)
                .environment(\.modelContext, modelContext)
                .background(Color.solsticeBackground.ignoresSafeArea())
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                if settings?.appLockEnabled == true {
                    appState.appLocked = true
                }
            case .active:
                break // user unlocks via AppLockView button
            @unknown default:
                break
            }
        }
        .task {
            // Ensure AppSettings exists so onboarding can write to it
            if settingsArray.isEmpty {
                let defaults = AppSettings()
                modelContext.insert(defaults)
                try? modelContext.save()
            }
            // Build lock manager once appState is stable
            if lockManager == nil {
                lockManager = AppLockManager(appState: appState)
            }
        }
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
