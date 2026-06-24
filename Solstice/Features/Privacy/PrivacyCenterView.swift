import SwiftUI
import SwiftData
import LocalAuthentication

// MARK: - PrivacyCenterView

struct PrivacyCenterView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query private var settingsArray: [AppSettings]
    @Query private var cycleEntries: [CycleEntry]
    @Query private var symptomLogs: [SymptomLog]
    @Query private var moodLogs: [MoodLog]

    private var settings: AppSettings? { settingsArray.first }

    @State private var showDeleteAlert = false
    @State private var showDeletedOverlay = false
    @State private var isExportingCSV = false
    @State private var exportError: String? = nil
    @State private var showShareSheet = false
    @State private var shareURL: URL? = nil
    @State private var appLockEnabled: Bool = false
    @State private var appLockFailedMessage: String? = nil
    @State private var cachedBiometryType: LABiometryType = .none

    // Static destination for NavigationLink usage
    static var destination: some View {
        PrivacyCenterView()
    }

    var body: some View {
        ZStack {
            List {
                heroSection
                whatStaysSection
                whatLeavesSection
                appLockSection
                exportSection
                deleteSection
                footerSection
            }
            .listStyle(.insetGrouped)
            .background(Color.solsticeBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                appLockEnabled = settings?.appLockEnabled ?? false
                cacheBiometryType()
            }

            // Delete confirmation overlay
            if showDeletedOverlay {
                deletedOverlay
            }
        }
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Delete Everything", role: .destructive) {
                performDeleteAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all your cycle logs, symptoms, mood entries, and settings from this iPhone. It cannot be undone.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheetView(activityItems: [url])
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.solsticeLockTint)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                Text("Your data stays here")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.solsticeTextPrimary)

                Text("Solstice stores everything on this iPhone using encrypted local storage. Nothing is sent to servers, no account is required, and no third-party analytics run in this app.")
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextSecondary)

                privacyBadge
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your data stays here. Solstice stores everything on this iPhone. Nothing is sent to servers. On this iPhone.")
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - What Stays Section

    private var whatStaysSection: some View {
        Section(header: Text("WHAT STAYS ON THIS IPHONE")) {
            dataRow(
                icon: "drop.fill",
                title: "Period & flow logs",
                subtitle: "Every date, flow level, and note you've entered."
            )
            dataRow(
                icon: "bolt.heart",
                title: "Symptoms",
                subtitle: "All symptom tags and custom symptoms."
            )
            dataRow(
                icon: "face.smiling",
                title: "Mood entries",
                subtitle: "All mood tags, any cycle."
            )
            dataRow(
                icon: "chart.xyaxis.line",
                title: "Cycle history",
                subtitle: "Lengths, dates, and predictions."
            )
            dataRow(
                icon: "gearshape",
                title: "Your settings",
                subtitle: "Cycle length preferences, notification settings."
            )
        }
        .listRowBackground(Color.solsticeSurface)
    }

    @ViewBuilder
    private func dataRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.solsticeLockTint.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.solsticeLockTint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.solsticeTextPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeTextSecondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 16))
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), stored on this iPhone")
    }

    // MARK: - What Leaves Section

    private var whatLeavesSection: some View {
        Section(header: Text("WHAT LEAVES THIS IPHONE")) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.solsticeSuccess.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.solsticeSuccess)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nothing — by default")
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Text("No data is sent anywhere automatically. The only ways data leaves this iPhone are: (1) if you choose to export it below, or (2) if you enable Apple Health sync in Settings and the Health app shares it per your Health privacy settings.")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Nothing leaves by default. No data is sent automatically.")

            Text("Apple Health data is governed by Apple's privacy policy, not Solstice's. Disable Health sync in Settings at any time.")
                .font(.callout)
                .foregroundStyle(Color.solsticeTextSecondary)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isStaticText)
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - App Lock Section

    private var appLockSection: some View {
        Section(header: Text("APP LOCK")) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.solsticeLockTint.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: biometryIconName)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.solsticeLockTint)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(biometryTitle)
                        .font(.body)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Text(appLockEnabled
                         ? "Face ID is on. Solstice will lock when you leave the app."
                         : "Require biometrics to open Solstice. Your data stays hidden even if someone has your phone.")
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)

                    if let msg = appLockFailedMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeWarning)
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appLockEnabled },
                    set: { newValue in
                        Task { await handleAppLockToggle(newValue) }
                    }
                ))
                .labelsHidden()
                .tint(Color.solsticeLockTint)
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(biometryTitle), toggle")
            .accessibilityValue(appLockEnabled ? "on" : "off")
            .accessibilityHint("Requires Face ID to open Solstice. Double-tap to \(appLockEnabled ? "disable" : "enable").")
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section(header: Text("EXPORT")) {
            Button {
                Task { await exportCSV() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.solsticeAccentSoft)
                            .frame(width: 28, height: 28)
                        Image(systemName: "tablecells")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.solsticeAccent)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export CSV")
                            .font(.body)
                            .foregroundStyle(Color.solsticeTextPrimary)
                        Text("A spreadsheet of every logged day, all symptoms, flow, and mood entries.")
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeTextSecondary)
                    }
                    Spacer()
                    if isExportingCSV {
                        ProgressView()
                            .tint(Color.solsticeAccent)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.solsticeAccent)
                    }
                }
                .frame(minHeight: 44)
            }
            .disabled(isExportingCSV)
            .accessibilityLabel("Export CSV, button")
            .accessibilityHint("Generates a file and opens the share sheet.")
            .accessibilityValue(isExportingCSV ? "Preparing, loading" : "")

            if let error = exportError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.solsticeWarning)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeWarning)
                }
            }

            Text("Once exported, a file on your device or in another app is outside Solstice's control.")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)

            privacyBadge
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section(header: Text("DANGER ZONE")) {
            Button {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                showDeleteAlert = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.solsticePeriod)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete All Data")
                            .font(.body)
                            .foregroundStyle(Color.solsticePeriod)
                        Text("Permanently removes all logs, settings, and cycle history from this iPhone. This cannot be undone.")
                            .font(.footnote)
                            .foregroundStyle(Color.solsticeTextSecondary)
                    }
                }
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Delete All Data, button")
            .accessibilityHint("Warning: permanently removes all data from this iPhone. This action cannot be undone.")
        }
        .listRowBackground(Color.solsticeSurface)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        Section {
            HStack(spacing: 4) {
                Text("Solstice v1.0")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeTextSecondary)
                Text("·")
                    .foregroundStyle(Color.solsticeTextSecondary)
                Text("Privacy policy")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeAccent)
                    .onTapGesture {}
                    .frame(minWidth: 44, minHeight: 44)
                Text("·")
                    .foregroundStyle(Color.solsticeTextSecondary)
                Text("Open source")
                    .font(.footnote)
                    .foregroundStyle(Color.solsticeAccent)
                    .onTapGesture {}
                    .frame(minWidth: 44, minHeight: 44)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 24)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Privacy Badge

    private var privacyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
            Text("On this iPhone")
                .font(.footnote)
                .foregroundStyle(Color.solsticeTextSecondary)
        }
    }

    // MARK: - Deleted Overlay

    private var deletedOverlay: some View {
        ZStack {
            Color.solsticeBackground.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.solsticeSuccess)
                Text("All data deleted")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.solsticeTextPrimary)
                Text("Solstice is now a clean slate.")
                    .font(.callout)
                    .foregroundStyle(Color.solsticeTextSecondary)
            }
        }
    }

    // MARK: - Biometry Helpers

    private var biometryIconName: String {
        switch cachedBiometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    private var biometryTitle: String {
        switch cachedBiometryType {
        case .faceID: return "Lock with Face ID"
        case .touchID: return "Lock with Touch ID"
        default: return "Lock with Device Passcode"
        }
    }

    private func cacheBiometryType() {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        cachedBiometryType = context.biometryType
    }

    // MARK: - Actions

    private func handleAppLockToggle(_ enable: Bool) async {
        appLockFailedMessage = nil
        if enable {
            let context = LAContext()
            let reason = "Enable app lock to protect your Solstice data."
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                if success {
                    appLockEnabled = true
                    settings?.appLockEnabled = true
                    try? modelContext.save()
                } else {
                    appLockEnabled = false
                    appLockFailedMessage = "Face ID couldn't be verified — lock not enabled."
                }
            } catch {
                appLockEnabled = false
                appLockFailedMessage = "Face ID couldn't be verified — lock not enabled."
            }
        } else {
            appLockEnabled = false
            settings?.appLockEnabled = false
            try? modelContext.save()
        }
    }

    private func exportCSV() async {
        isExportingCSV = true
        exportError = nil

        do {
            let csvString = buildCSV()
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("solstice_export_\(Date().timeIntervalSince1970).csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            shareURL = fileURL
            showShareSheet = true
        } catch {
            exportError = "Couldn't create the export file. Try again."
        }

        isExportingCSV = false
    }

    private func buildCSV() -> String {
        let fmt = ISO8601DateFormatter()

        func csvField(_ s: String) -> String {
            // RFC 4180: wrap in quotes if contains comma, newline, or quote; escape inner quotes
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }

        var sections: [String] = []

        // --- Cycles ---
        var cycleLines = ["cycle_id,periodStart,periodEnd,cycleLength,notes"]
        for entry in cycleEntries.sorted(by: { $0.periodStart < $1.periodStart }) {
            let cols = [
                entry.id.uuidString,
                fmt.string(from: entry.periodStart),
                entry.periodEnd.map { fmt.string(from: $0) } ?? "",
                entry.cycleLength.map { "\($0)" } ?? "",
                csvField(entry.notes)
            ]
            cycleLines.append(cols.joined(separator: ","))
        }
        sections.append(cycleLines.joined(separator: "\n"))

        // --- Symptoms ---
        var symptomLines = ["cycle_id,date,symptom,intensity"]
        for log in symptomLogs.sorted(by: { $0.date < $1.date }) {
            let cycleID = cycleEntries.first(where: { $0.symptomLogs.contains(log) })?.id.uuidString ?? ""
            let cols = [cycleID, fmt.string(from: log.date), log.symptom.rawValue, "\(log.intensity)"]
            symptomLines.append(cols.joined(separator: ","))
        }
        sections.append(symptomLines.joined(separator: "\n"))

        // --- Moods ---
        var moodLines = ["cycle_id,date,mood"]
        for log in moodLogs.sorted(by: { $0.date < $1.date }) {
            let cycleID = cycleEntries.first(where: { $0.moodLogs.contains(log) })?.id.uuidString ?? ""
            let cols = [cycleID, fmt.string(from: log.date), log.mood.rawValue]
            moodLines.append(cols.joined(separator: ","))
        }
        sections.append(moodLines.joined(separator: "\n"))

        return sections.joined(separator: "\n\n")
    }

    private func performDeleteAll() {
        // Delete all records
        for entry in cycleEntries {
            modelContext.delete(entry)
        }
        for log in symptomLogs {
            modelContext.delete(log)
        }
        for log in moodLogs {
            modelContext.delete(log)
        }
        // Reset settings but keep hasCompletedOnboarding = true
        if let s = settings {
            s.averageCycleLength = 28
            s.averagePeriodLength = 5
            s.lastPeriodStart = nil
            s.appLockEnabled = false
            s.notificationsEnabled = false
            s.healthKitSyncEnabled = false
            // Keep hasCompletedOnboarding = true so no re-onboarding
        }
        try? modelContext.save()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        showDeletedOverlay = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showDeletedOverlay = false
        }
    }
}

// MARK: - ShareSheetView

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
