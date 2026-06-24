import SwiftUI
import SwiftData
import LocalAuthentication

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case cycleSetup
    case appLock
    case done

    var isOptional: Bool {
        switch self {
        case .appLock, .done: return true
        default: return false
        }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // Local form state — only persisted on completion
    @State private var step: OnboardingStep = .welcome
    @State private var lastPeriodStart: Date = Calendar.current.startOfDay(for: Date())
    @State private var cycleLength: Int = 28
    @State private var periodLength: Int = 5
    @State private var enableAppLock: Bool = false
    @State private var biometricsAvailable: Bool = false
    @State private var isAuthenticating: Bool = false
    @State private var authError: String? = nil
    @State private var isSaving: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            Color.solsticeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Page content via TabView for swipe support
                TabView(selection: $step) {
                    WelcomeStepView()
                        .tag(OnboardingStep.welcome)

                    CycleSetupStepView(
                        lastPeriodStart: $lastPeriodStart,
                        cycleLength: $cycleLength,
                        periodLength: $periodLength
                    )
                    .tag(OnboardingStep.cycleSetup)

                    AppLockStepView(
                        enableAppLock: $enableAppLock,
                        biometricsAvailable: biometricsAvailable,
                        isAuthenticating: isAuthenticating,
                        authError: authError,
                        onEnableTapped: handleAppLockToggle
                    )
                    .tag(OnboardingStep.appLock)

                    DoneStepView()
                        .tag(OnboardingStep.done)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.86), value: step)

                bottomControls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.solsticeAccent : Color.solsticeSeparator)
                    .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        VStack(spacing: 12) {
            if step == .appLock {
                // Skip for optional step
                Button("Skip") {
                    advanceStep()
                }
                .font(.body)
                .foregroundStyle(Color.solsticeTextSecondary)
                .frame(minHeight: 44)
            }

            primaryButton
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case .welcome:
            SolsticePrimaryButton(label: "Get started", isLoading: false) {
                advanceStep()
            }
        case .cycleSetup:
            SolsticePrimaryButton(label: "Continue", isLoading: false) {
                advanceStep()
            }
        case .appLock:
            SolsticePrimaryButton(label: "Continue", isLoading: isAuthenticating) {
                advanceStep()
            }
        case .done:
            SolsticePrimaryButton(label: "Start tracking", isLoading: isSaving) {
                completeOnboarding()
            }
        }
    }

    // MARK: - Navigation

    private func advanceStep() {
        let allCases = OnboardingStep.allCases
        let nextRaw = step.rawValue + 1
        if nextRaw < allCases.count, let next = OnboardingStep(rawValue: nextRaw) {
            withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.86)) {
                step = next
            }
        }
    }

    // MARK: - App Lock handling

    private func handleAppLockToggle() {
        guard biometricsAvailable else { return }
        isAuthenticating = true
        authError = nil

        Task {
            let context = LAContext()
            var error: NSError?
            let canEval = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
            guard canEval else {
                await MainActor.run {
                    authError = "Biometrics unavailable on this device."
                    isAuthenticating = false
                }
                return
            }
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: "Authenticate to enable App Lock for Solstice"
                )
                await MainActor.run {
                    enableAppLock = success
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    authError = "Couldn't verify — Face ID or passcode is required."
                    isAuthenticating = false
                }
            }
        }
    }

    // MARK: - Completion

    private func completeOnboarding() {
        isSaving = true
        let descriptor = FetchDescriptor<AppSettings>()
        let settings: AppSettings
        if let existing = try? modelContext.fetch(descriptor).first {
            settings = existing
        } else {
            settings = AppSettings()
            modelContext.insert(settings)
        }
        settings.lastPeriodStart = lastPeriodStart
        settings.averageCycleLength = cycleLength
        settings.averagePeriodLength = periodLength
        settings.appLockEnabled = enableAppLock
        settings.hasCompletedOnboarding = true

        do {
            try modelContext.save()
        } catch {
            // Non-fatal — onboarding still closes; settings may not persist
        }
        isSaving = false
    }

    // MARK: - Lifecycle

    private func checkBiometrics() {
        let context = LAContext()
        var error: NSError?
        biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
}

// MARK: - Welcome Step

private struct WelcomeStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Wordmark glyph placeholder
                ZStack {
                    Circle()
                        .fill(Color.solsticeAccentSoft)
                        .frame(width: 80, height: 80)
                    Image(systemName: "moon.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.solsticeAccent)
                }
                .accessibilityHidden(true)
                .padding(.bottom, 32)

                Text("Solstice")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 12)

                Text("Your cycle, kept private.")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)

                Text("Solstice predicts your period and fertile window right here on your iPhone. No account. No cloud. Your data never leaves this device unless you choose to export it.")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)

                PrivacyBadge()

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Cycle Setup Step

private struct CycleSetupStepView: View {
    @Binding var lastPeriodStart: Date
    @Binding var cycleLength: Int
    @Binding var periodLength: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Spacer(minLength: 20)

                // Last Period Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("When did your last period start?")
                        .font(.title.bold())
                        .foregroundStyle(Color.solsticeTextPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Pick the first day of bleeding. An estimate is fine — you can change it later.")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextSecondary)

                    DatePicker(
                        "Last period start",
                        selection: $lastPeriodStart,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .tint(Color.solsticeAccent)
                    .accessibilityLabel("Last period start date")
                    .frame(maxWidth: .infinity)
                }

                // Cycle Length
                VStack(alignment: .leading, spacing: 8) {
                    Text("How long is your cycle, usually?")
                        .font(.title2.bold())
                        .foregroundStyle(Color.solsticeTextPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("From the first day of one period to the first day of the next. Most are 21–35 days.")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextSecondary)

                    LengthPickerRow(
                        value: $cycleLength,
                        range: 21...45,
                        label: "Cycle length",
                        unit: "days"
                    )
                }

                // Period Length
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many days does your period last?")
                        .font(.title2.bold())
                        .foregroundStyle(Color.solsticeTextPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Typically 3–7 days.")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextSecondary)

                    LengthPickerRow(
                        value: $periodLength,
                        range: 2...10,
                        label: "Period length",
                        unit: "days"
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Length Picker Row

private struct LengthPickerRow: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    let unit: String

    var body: some View {
        HStack(spacing: 20) {
            Button {
                if value > range.lowerBound {
                    value -= 1
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.solsticeAccent)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Decrease \(label)")

            Text("\(value) \(unit)")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Color.solsticeTextPrimary)
                .frame(minWidth: 120)
                .multilineTextAlignment(.center)
                .accessibilityLabel("\(label), \(value) \(unit)")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        if value < range.upperBound { value += 1 }
                    case .decrement:
                        if value > range.lowerBound { value -= 1 }
                    @unknown default:
                        break
                    }
                }

            Button {
                if value < range.upperBound {
                    value += 1
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.solsticeAccent)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Increase \(label)")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - App Lock Step

private struct AppLockStepView: View {
    @Binding var enableAppLock: Bool
    let biometricsAvailable: Bool
    let isAuthenticating: Bool
    let authError: String?
    let onEnableTapped: () -> Void

    var biometrySymbol: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return "lock.fill"
        }
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 32)

                Image(systemName: biometrySymbol)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.solsticeLockTint)
                    .accessibilityHidden(true)

                Text("Lock Solstice with Face ID?")
                    .font(.title.bold())
                    .foregroundStyle(Color.solsticeTextPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Require Face ID to open the app, so your cycle stays yours even if someone has your phone. You can change this anytime in Settings.")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextSecondary)
                    .multilineTextAlignment(.center)

                if let error = authError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeWarning)
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeTextPrimary)
                    }
                    .padding(.horizontal, 16)
                    .multilineTextAlignment(.center)
                }

                if biometricsAvailable && !enableAppLock {
                    SolsticePrimaryButton(
                        label: "Turn on Face ID",
                        isLoading: isAuthenticating,
                        leadingSymbol: biometrySymbol
                    ) {
                        onEnableTapped()
                    }
                } else if enableAppLock {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.solsticeSuccess)
                        Text("App Lock enabled")
                            .font(.headline)
                            .foregroundStyle(Color.solsticeTextPrimary)
                    }
                    .padding(.vertical, 12)
                } else {
                    Text("Face ID is not available on this device. You can enable App Lock later in Settings.")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeWarning)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Done Step

private struct DoneStepView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.solsticeAccentSoft)
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.solsticeAccent)
            }
            .accessibilityHidden(true)

            Text("You're all set.")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.solsticeTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Your cycle is ready to track. Everything stays on this iPhone.")
                .font(.body)
                .foregroundStyle(Color.solsticeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            PrivacyBadge()

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Shared Components

struct PrivacyBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
            Text("On this iPhone")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("On this iPhone")
    }
}

struct SolsticePrimaryButton: View {
    let label: String
    let isLoading: Bool
    var leadingSymbol: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .accessibilityLabel("Loading")
                } else {
                    HStack(spacing: 8) {
                        if let symbol = leadingSymbol {
                            Image(systemName: symbol)
                                .font(.headline)
                        }
                        Text(label)
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
        }
        .background(Color.solsticeAccent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Authenticating" : label)
        .accessibilityValue(isLoading ? "loading" : "")
    }
}
