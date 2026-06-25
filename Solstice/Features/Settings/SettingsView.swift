import SwiftUI
import SwiftData
import UserNotifications
#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store

    @Query private var settingsArray: [AppSettings]
    @Query(sort: \CycleEntry.periodStart, order: .reverse) private var cycles: [CycleEntry]

    private var settings: AppSettings? { settingsArray.first }

    // Notification state
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var periodReminderEnabled = false
    @State private var fertileReminderEnabled = false
    @State private var periodReminderDays = 3

    // Health state
    @State private var healthSyncEnabled = false
    @State private var healthAuthError: String? = nil
    @State private var isRequestingHealth = false

    // Appearance
    @State private var appearanceSelection: ColorSchemePreference = .system

    // Alerts
    @State private var showRerunSetupAlert = false

    // Paywall
    @State private var showPaywall = false

    // Version info
    private var appVersion: String {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(ver) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                premiumSection
                cycleSection
                notificationsSection
                healthSection
                appearanceSection
                privacySection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .background(Color.solsticeBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadNotificationStatus()
                if let s = settings {
                    periodReminderEnabled = s.notificationsEnabled
                    healthSyncEnabled = s.healthKitSyncEnabled
                    appearanceSelection = ColorSchemePreference(from: appState.colorSchemePreference)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(
            "Restore Purchase",
            isPresented: Binding(
                get: { store.purchaseError != nil && !showPaywall },
                set: { if !$0 { store.purchaseError = nil } }
            )
        ) {
            Button("OK") { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
        .alert("Re-run Setup?", isPresented: $showRerunSetupAlert) {
            Button("Re-run Setup") {
                // Reset cycle/period prefs only — not logs
                settings?.averageCycleLength = 28
                settings?.averagePeriodLength = 5
                settings?.hasCompletedOnboarding = false
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your logs and history won't be changed — only your cycle length and period preferences will be reset.")
        }
    }

    // MARK: - Solstice+ Section

    @ViewBuilder
    private var premiumSection: some View {
        Section {
            if store.isPremium {
                HStack(spacing: 12) {
                    tileIcon("sparkles", color: .solsticeAccent, bg: .solsticeAccentSoft)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Solstice+")
                            .font(.body)
                            .foregroundStyle(Color.solsticeTextPrimary)
                        Text("Active — thank you for supporting private software.")
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.solsticeSuccess)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Solstice Plus is active")

                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        tileIcon("creditcard", color: .solsticeTextSecondary, bg: .solsticeSurfaceSecondary)
                        Text("Manage Subscription")
                            .font(.body)
                            .foregroundStyle(Color.solsticeTextPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(Color.solsticeTextTertiary)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel("Manage Subscription")
                .accessibilityHint("Opens your Apple Account subscriptions.")
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        tileIcon("sparkles", color: .solsticeAccent, bg: .solsticeAccentSoft)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Solstice+")
                                .font(.body)
                                .foregroundStyle(Color.solsticeTextPrimary)
                            Text("Fertile window, advanced insights, Health sync & export.")
                                .font(.footnote)
                                .foregroundStyle(Color.solsticeTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.solsticeTextTertiary)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel("Unlock Solstice Plus")
                .accessibilityHint("Opens the Solstice Plus plans.")

                Button {
                    Task { await store.restore() }
                } label: {
                    HStack(spacing: 12) {
                        tileIcon("arrow.clockwise", color: .solsticeTextSecondary, bg: .solsticeSurfaceSecondary)
                        Text("Restore Purchase")
                            .font(.body)
                            .foregroundStyle(Color.solsticeTextPrimary)
                        Spacer()
                        if store.isPurchasing {
                            ProgressView().tint(Color.solsticeAccent)
                        }
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel("Restore Purchase")
            }
        } header: {
            Text("SOLSTICE+")
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Cycle Section

    private var cycleSection: some View {
        Section(
            header: Text("CYCLE SETUP"),
            footer: Text("Solstice refines these averages automatically as you log more cycles. Editing them resets to manual values.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        ) {
            // Average Cycle Length
            HStack(spacing: 12) {
                tileIcon("arrow.triangle.2.circlepath", color: .solsticeAccent, bg: .solsticeAccentSoft)
                Text("Average Cycle Length")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)
                Spacer()
                Stepper(
                    "\(settings?.averageCycleLength ?? 28) days",
                    value: Binding(
                        get: { settings?.averageCycleLength ?? 28 },
                        set: { newVal in
                            settings?.averageCycleLength = max(21, min(45, newVal))
                            try? modelContext.save()
                        }
                    ),
                    in: 21...45
                )
                .labelsHidden()
                .accessibilityLabel("Average cycle length, \(settings?.averageCycleLength ?? 28) days")
            }
            .frame(minHeight: 44)

            // Average Period Length
            HStack(spacing: 12) {
                tileIcon("drop.fill", color: .solsticePeriod, bg: .solsticePeriodSoft)
                Text("Average Period Length")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)
                Spacer()
                Stepper(
                    "\(settings?.averagePeriodLength ?? 5) days",
                    value: Binding(
                        get: { settings?.averagePeriodLength ?? 5 },
                        set: { newVal in
                            settings?.averagePeriodLength = max(2, min(10, newVal))
                            try? modelContext.save()
                        }
                    ),
                    in: 2...10
                )
                .labelsHidden()
                .accessibilityLabel("Average period length, \(settings?.averagePeriodLength ?? 5) days")
            }
            .frame(minHeight: 44)

            // Last Period Start
            HStack(spacing: 12) {
                tileIcon("calendar.badge.clock", color: .solsticeAccent, bg: .solsticeAccentSoft)
                DatePicker(
                    "Last Period Start",
                    selection: Binding(
                        get: { settings?.lastPeriodStart ?? Date() },
                        set: { newDate in
                            settings?.lastPeriodStart = newDate
                            try? modelContext.save()
                        }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .font(.body)
                .tint(Color.solsticeAccent)
                .accessibilityLabel("Last period start date")
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section(
            header: Text("NOTIFICATIONS"),
            footer: notificationFooter
        ) {
            // Period Reminder
            HStack(spacing: 12) {
                tileIcon("bell", color: .solsticeAccent, bg: .solsticeAccentSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Period Reminder")
                        .font(.body)
                        .foregroundStyle(notificationsDenied ? Color.solsticeTextTertiary : Color.solsticeTextPrimary)
                    Text(periodReminderEnabled ? "\(periodReminderDays) days before" : "Off")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { periodReminderEnabled && !notificationsDenied },
                    set: { newValue in
                        Task { await handleNotificationToggle(enabled: newValue, isPeriod: true) }
                    }
                ))
                .labelsHidden()
                .tint(Color.solsticeAccent)
                .disabled(notificationsDenied)
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Period Reminder toggle")
            .accessibilityValue(periodReminderEnabled ? "on" : "off")
            .accessibilityHint("Reminds you before your predicted period.")

            // Fertile Window Reminder
            HStack(spacing: 12) {
                tileIcon("leaf.fill", color: .solsticeFertile, bg: .solsticeFertileSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fertile Window Reminder")
                        .font(.body)
                        .foregroundStyle(notificationsDenied ? Color.solsticeTextTertiary : Color.solsticeTextPrimary)
                    Text(fertileReminderEnabled ? "Day of" : "Off")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { fertileReminderEnabled && !notificationsDenied },
                    set: { newValue in
                        Task { await handleNotificationToggle(enabled: newValue, isPeriod: false) }
                    }
                ))
                .labelsHidden()
                .tint(Color.solsticeAccent)
                .disabled(notificationsDenied)
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Fertile Window Reminder toggle")
            .accessibilityValue(fertileReminderEnabled ? "on" : "off")

            if notificationsDenied {
                openSettingsRow(label: "Notifications are disabled in iPhone Settings.")
            }
        }
        .listRowBackground(Color.solsticeSurface)
    }

    private var notificationFooter: some View {
        HStack(spacing: 6) {
            Text("Notifications are scheduled on-device. Solstice does not send push notifications through a server.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
            Text("On this iPhone")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        Section(
            header: Text("APPLE HEALTH"),
            footer: Text("Apple Health data is governed by Apple's Privacy Policy. Disable sync at any time here or in the Health app → Sources.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        ) {
            // Sync Toggle
            HStack(spacing: 12) {
                tileIcon("heart.text.square", color: .solsticeSuccess, bg: Color.solsticeSuccess.opacity(0.15))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync with Apple Health")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    if let err = healthAuthError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeWarning)
                    }
                }
                Spacer()
                if isRequestingHealth {
                    ProgressView()
                        .tint(Color.solsticeAccent)
                } else {
                    Toggle("", isOn: Binding(
                        get: { healthSyncEnabled },
                        set: { newValue in
                            Task { await handleHealthToggle(newValue) }
                        }
                    ))
                    .labelsHidden()
                    .tint(Color.solsticeAccent)
                }
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sync with Apple Health, toggle")
            .accessibilityValue(healthSyncEnabled ? "on" : "off")
            .accessibilityHint("Requires iPhone Settings permission. Will show a system authorization sheet.")

            // What gets shared
            Text("When enabled, Solstice reads and writes: Menstrual Flow, Cycle Start. Solstice never reads other Health categories. Apple controls what other apps can access from the Health app.")
                .font(.callout)
                .foregroundStyle(Color.solsticeTextSecondary)
                .frame(minHeight: 44)
                .accessibilityAddTraits(.isStaticText)
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section(
            header: Text("APPEARANCE"),
            footer: Text("Solstice respects your system setting by default.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        ) {
            HStack(spacing: 12) {
                tileIcon("circle.lefthalf.filled", color: .solsticeTextSecondary, bg: .solsticeSurfaceSecondary)
                Text("Appearance")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)
                Spacer()
                Picker("Appearance", selection: $appearanceSelection) {
                    Text("System").tag(ColorSchemePreference.system)
                    Text("Light").tag(ColorSchemePreference.light)
                    Text("Dark").tag(ColorSchemePreference.dark)
                }
                .pickerStyle(.menu)
                .tint(Color.solsticeTextSecondary)
                .onChange(of: appearanceSelection) { _, newValue in
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    appState.colorSchemePreference = newValue.colorScheme
                }
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section(header: Text("PRIVACY")) {
            NavigationLink(destination: PrivacyCenterView()) {
                HStack(spacing: 12) {
                    tileIcon("lock.shield", color: .solsticeLockTint, bg: Color.solsticeLockTint.opacity(0.15))
                    Text("Privacy Center")
                        .font(.body)
                        .foregroundStyle(Color.solsticeLockTint)
                }
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Privacy Center, button")
            .accessibilityHint("Opens the Privacy Center.")

            NavigationLink(destination: PrivacyCenterView()) {
                HStack(spacing: 12) {
                    tileIcon("faceid", color: .solsticeLockTint, bg: Color.solsticeLockTint.opacity(0.15))
                    Text("App Lock")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Spacer()
                    Text(settings?.appLockEnabled == true ? "On" : "Off")
                        .font(.callout)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
                .frame(minHeight: 44)
            }
            .accessibilityLabel("App Lock")
            .accessibilityValue(settings?.appLockEnabled == true ? "On" : "Off")
            .accessibilityHint("Navigate to Privacy Center to manage App Lock.")
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section(
            header: Text("ABOUT"),
            footer: Text("Made with care. No tracking, no cloud.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
        ) {
            // Version
            HStack(spacing: 12) {
                tileIcon("info.circle", color: .solsticeTextSecondary, bg: .solsticeSurfaceSecondary)
                Text("Solstice")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)
                Spacer()
                Text(appVersion)
                    .font(.callout)
                    .foregroundStyle(Color.solsticeTextSecondary)
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Solstice, version \(appVersion)")

            // Open Source Licenses
            NavigationLink(destination: LicensesView()) {
                HStack(spacing: 12) {
                    tileIcon("doc.text", color: .solsticeTextSecondary, bg: .solsticeSurfaceSecondary)
                    Text("Open-Source Licenses")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                }
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Open-Source Licenses, button")

            // Send Feedback
            Button {
                sendFeedback()
            } label: {
                HStack(spacing: 12) {
                    tileIcon("envelope", color: .solsticeAccent, bg: .solsticeAccentSoft)
                    Text("Send Feedback")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.solsticeTextTertiary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Send Feedback, button")
            .accessibilityHint("Opens Mail.")

            // Re-run Setup
            Button {
                showRerunSetupAlert = true
            } label: {
                HStack(spacing: 12) {
                    tileIcon("arrow.counterclockwise", color: .solsticeTextSecondary, bg: .solsticeSurfaceSecondary)
                    Text("Re-run Setup")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.solsticeTextTertiary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Re-run Setup, button")
            .accessibilityHint("Resets cycle parameters — not your logs.")
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func tileIcon(_ name: String, color: Color, bg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(bg)
                .frame(width: 28, height: 28)
            Image(systemName: name)
                .font(.system(size: 14))
                .foregroundStyle(color)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func openSettingsRow(label: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
            Spacer()
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.footnote)
            .foregroundStyle(Color.solsticeAccent)
            .frame(minWidth: 44, minHeight: 44)
        }
    }

    private var notificationsDenied: Bool {
        notificationAuthStatus == .denied
    }

    private func loadNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        notificationAuthStatus = settings.authorizationStatus
    }

    private func handleNotificationToggle(enabled: Bool, isPeriod: Bool) async {
        if enabled {
            let center = UNUserNotificationCenter.current()
            let status = await center.notificationSettings()
            if status.authorizationStatus == .notDetermined {
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                await MainActor.run {
                    notificationAuthStatus = granted ? .authorized : .denied
                    if granted {
                        if isPeriod { periodReminderEnabled = true } else { fertileReminderEnabled = true }
                        settings?.notificationsEnabled = true
                        try? modelContext.save()
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            } else if status.authorizationStatus == .authorized {
                await MainActor.run {
                    if isPeriod { periodReminderEnabled = true } else { fertileReminderEnabled = true }
                    settings?.notificationsEnabled = true
                    try? modelContext.save()
                }
            }
        } else {
            await MainActor.run {
                if isPeriod { periodReminderEnabled = false } else { fertileReminderEnabled = false }
                if !periodReminderEnabled && !fertileReminderEnabled {
                    settings?.notificationsEnabled = false
                    try? modelContext.save()
                }
            }
        }
    }

    private func handleHealthToggle(_ enable: Bool) async {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            healthAuthError = "Apple Health is not available on this device."
            healthSyncEnabled = false
            return
        }

        if enable {
            isRequestingHealth = true
            healthAuthError = nil

            let store = HKHealthStore()
            guard let menstrualFlowType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
                healthAuthError = "Health access wasn't granted."
                isRequestingHealth = false
                healthSyncEnabled = false
                return
            }

            do {
                try await store.requestAuthorization(
                    toShare: [menstrualFlowType],
                    read: [menstrualFlowType]
                )
                let status = store.authorizationStatus(for: menstrualFlowType)
                if status == .sharingAuthorized {
                    healthSyncEnabled = true
                    settings?.healthKitSyncEnabled = true
                    try? modelContext.save()
                    await writeExistingCyclesToHealth(store: store, type: menstrualFlowType)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else {
                    healthSyncEnabled = false
                    healthAuthError = "Health access wasn't granted. You can change this in iPhone Settings → Health → Solstice."
                }
            } catch {
                healthSyncEnabled = false
                healthAuthError = "Health access wasn't granted. You can change this in iPhone Settings → Health → Solstice."
            }
            isRequestingHealth = false
        } else {
            healthSyncEnabled = false
            settings?.healthKitSyncEnabled = false
            try? modelContext.save()
        }
        #else
        healthAuthError = "HealthKit is not available."
        healthSyncEnabled = false
        #endif
    }

    #if canImport(HealthKit)
    private func writeExistingCyclesToHealth(store: HKHealthStore, type: HKCategoryType) async {
        for cycle in cycles {
            guard let periodEnd = cycle.periodEnd else { continue }
            // Flow level is not stored in the current data model (no dedicated field in CycleEntry).
            // Use .none to avoid misrepresenting intensity; a future model update can map real values.
            let sample = HKCategorySample(
                type: type,
                value: HKCategoryValueMenstrualFlow.none.rawValue,
                start: cycle.periodStart,
                end: periodEnd
            )
            try? await store.save(sample)
        }
    }
    #endif

    private func sendFeedback() {
        let email = "feedback@solstice.app"
        if let url = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = email
        }
    }
}

// MARK: - ColorSchemePreference

enum ColorSchemePreference: String, CaseIterable {
    case system, light, dark

    init(from scheme: ColorScheme?) {
        switch scheme {
        case .light: self = .light
        case .dark: self = .dark
        default: self = .system
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - LicensesView

struct LicensesView: View {
    private let licenses: [(String, String)] = [
        ("Swift Charts", "Apple Inc. — Part of Swift/SwiftUI framework. No separate license."),
        ("SwiftData", "Apple Inc. — Part of the Apple SDK."),
        ("HealthKit", "Apple Inc. — Part of the Apple SDK."),
    ]

    var body: some View {
        List {
            ForEach(licenses, id: \.0) { name, text in
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Text(text)
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
                .padding(.vertical, 4)
                .frame(minHeight: 44)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.solsticeBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Open-Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
