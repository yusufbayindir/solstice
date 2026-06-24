import SwiftUI
import LocalAuthentication

// MARK: - AppLockView

struct AppLockView: View {
    @Environment(AppState.self) private var appState
    let lockManager: AppLockManager

    @State private var isAuthenticating: Bool = false
    @State private var unlockError: String? = nil
    @State private var isBiometryLocked: Bool = false
    @State private var showFirstTimeBadge: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage("hasSeenFirstLock") private var hasSeenFirstLock: Bool = false

    // MARK: - Biometry State

    private var biometryType: LABiometryType { lockManager.biometryType }
    private var canEvaluate: Bool { lockManager.canEvaluateAnyPolicy }

    private var unlockSymbol: String {
        guard !isBiometryLocked else { return "lock.fill" }
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "lock.fill"
        default: return "lock.fill"
        }
    }

    private var unlockLabel: String {
        guard canEvaluate else { return "Enter Passcode" }
        if isBiometryLocked { return "Enter Passcode" }
        switch biometryType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default: return "Enter Passcode"
        }
    }

    private var unlockHint: String {
        if isBiometryLocked || biometryType == .none {
            return "Double-tap to enter your iPhone passcode."
        }
        switch biometryType {
        case .faceID: return "Double-tap to authenticate with Face ID."
        case .touchID: return "Double-tap to authenticate with Touch ID."
        default: return "Double-tap to enter your iPhone passcode."
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 1: Blur shield
            blurShield

            // Layer 2: Content
            if canEvaluate {
                standardContent
            } else {
                noPasscodeContent
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if !hasSeenFirstLock {
                showFirstTimeBadge = true
            }
            // Trigger authentication automatically after a short delay
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                await triggerUnlock()
            }
        }
    }

    // MARK: - Blur Shield

    private var blurShield: some View {
        Group {
            if reduceTransparency {
                Color.solsticeBackground
                    .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Standard Lock Content

    private var standardContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                contentStack

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            // Glyph
            Image(systemName: "moon.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
                .padding(.bottom, 24)

            // Wordmark
            Text("Solstice")
                .font(.title.bold())
                .foregroundStyle(Color.solsticeTextPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 12)

            // Tagline
            Text("Your cycle. Your phone. Your privacy.")
                .font(.callout)
                .foregroundStyle(Color.solsticeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 48)

            // Lock status
            VStack(spacing: 8) {
                Text("Solstice is locked.")
                    .font(.subheadline)
                    .foregroundStyle(Color.solsticeTextSecondary)

                if showFirstTimeBadge && !hasSeenFirstLock {
                    Text("You just enabled App Lock. Authenticate to continue.")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                        .multilineTextAlignment(.center)
                        .onAppear {
                            hasSeenFirstLock = true
                        }
                }
            }
            .padding(.bottom, 12)

            // Error label
            if let error = unlockError {
                errorLabel(message: error)
                    .padding(.bottom, 12)
            }

            // Unlock button
            unlockButton
                .padding(.bottom, 24)

            // Privacy badge
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeLockTint)
                    .accessibilityHidden(true)
                Text("Your data stays on this device.")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeTextSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your data stays on this device.")
        }
    }

    // MARK: - Error Label

    private func errorLabel(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(Color.solsticeWarning)
                .accessibilityHidden(true)
            Text(message)
                .font(.callout)
                .foregroundStyle(Color.solsticeTextPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }

    // MARK: - Unlock Button

    private var unlockButton: some View {
        Button {
            Task { await triggerUnlock() }
        } label: {
            ZStack {
                if isAuthenticating {
                    if reduceMotion {
                        Image(systemName: "lock.open")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: unlockSymbol)
                            .font(.headline)
                        Text(unlockLabel)
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
        }
        .background(Color.solsticeAccent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(isAuthenticating)
        .accessibilityLabel(isAuthenticating ? "Authenticating" : unlockLabel)
        .accessibilityValue(isAuthenticating ? "loading" : "")
        .accessibilityHint(isAuthenticating ? "" : unlockHint)
    }

    // MARK: - No Passcode Content

    private var noPasscodeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.solsticeWarning)
                    .accessibilityHidden(true)

                Text("Can't unlock Solstice")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("No passcode is set on this iPhone. Set a passcode in iPhone Settings to regain access.")
                    .font(.callout)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .multilineTextAlignment(.center)

                Button("Open iPhone Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(Color.solsticeAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("Open iPhone Settings")
                .accessibilityHint("Double-tap to open iPhone Settings where you can set a passcode.")
            }
            .padding(.all, 16)
            .background(Color.solsticeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeLockTint)
                    .accessibilityHidden(true)
                Text("Your data stays on this device.")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeTextSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your data stays on this device.")
            .padding(.bottom, 32)
        }
    }

    // MARK: - Authentication

    private func triggerUnlock() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        unlockError = nil

        let result = await lockManager.unlock()

        isAuthenticating = false

        switch result {
        case .success:
            // appState.appLocked is already set to false by lockManager
            // Provide success haptic
            UINotificationFeedbackGenerator().notificationOccurred(.success)

        case .failed(let message):
            unlockError = message
            isBiometryLocked = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)

        case .biometryLocked:
            isBiometryLocked = true
            unlockError = "Face ID is locked — use your passcode to unlock Solstice."
            UINotificationFeedbackGenerator().notificationOccurred(.error)

        case .cancelled:
            // User cancelled — reset to idle
            break

        case .noPasscodeSet:
            // Handled by noPasscodeContent
            break
        }
    }
}
