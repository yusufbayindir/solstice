import SwiftUI
import LocalAuthentication

// MARK: - AppLockManager

@MainActor
final class AppLockManager: ObservableObject {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Scene Phase Handler

    /// Call this when scenePhase becomes .active while appLockEnabled is true.
    func handleForeground(appLockEnabled: Bool) {
        guard appLockEnabled else { return }
        appState.appLocked = true
    }

    // MARK: - Unlock

    /// Attempt biometric/passcode authentication.
    /// On success, sets appState.appLocked = false.
    func unlock() async -> UnlockResult {
        let context = LAContext()
        var policyError: NSError?

        // Determine best available policy
        let canUseBiometric = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &policyError
        )
        let canUsePasscode = context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &policyError
        )

        guard canUsePasscode else {
            return .noPasscodeSet
        }

        let policy: LAPolicy = canUseBiometric
            ? .deviceOwnerAuthentication   // covers biometric + passcode fallback
            : .deviceOwnerAuthentication

        let reason = "Unlock Solstice to access your cycle data."

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if success {
                appState.appLocked = false
                return .success
            } else {
                return .failed(message: "Couldn't verify — try again.")
            }
        } catch let laError as LAError {
            switch laError.code {
            case .biometryLockout:
                return .biometryLocked
            case .userCancel, .appCancel, .systemCancel:
                return .cancelled
            case .biometryNotEnrolled, .biometryNotAvailable:
                // Fall through to passcode-only path automatically on next attempt
                return .failed(message: "Couldn't verify — try again.")
            default:
                return .failed(message: "Couldn't verify — try again.")
            }
        } catch {
            return .failed(message: "Couldn't verify — try again.")
        }
    }

    // MARK: - Biometry Info

    var biometryType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        return context.biometryType
    }

    var canEvaluateAnyPolicy: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
}

// MARK: - UnlockResult

enum UnlockResult {
    case success
    case failed(message: String)
    case cancelled
    case biometryLocked
    case noPasscodeSet
}
