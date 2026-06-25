import SwiftUI
import StoreKit

// MARK: - PaywallView
//
// Value-first paywall for Solstice+. Lifetime is the visually emphasised hero
// (an anti-subscription statement that matches the privacy brand), with annual
// as the default subscription and monthly as the low entry point. Privacy proof
// points sit above the price, because the privacy guarantee is what's being sold.

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// One-line reason the paywall was shown (e.g. "Unlock fertile window").
    var context: String? = nil

    @State private var selectedProductID: String = StoreManager.lifetimeID

    var body: some View {
        ZStack {
            Color.solsticeBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    proofPoints
                    featureList
                    planPicker
                    purchaseButton
                    legalRow
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
        .onChange(of: store.isPremium) { _, premium in
            if premium { dismiss() }
        }
        .alert(
            "Purchase Issue",
            isPresented: Binding(
                get: { store.purchaseError != nil },
                set: { if !$0 { store.purchaseError = nil } }
            )
        ) {
            Button("OK") { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.solsticeTextTertiary)
                .padding(16)
        }
        .accessibilityLabel("Close")
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.solsticeAccentSoft)
                    .frame(width: 84, height: 84)
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.solsticeAccent)
            }
            .accessibilityHidden(true)
            .padding(.top, 36)

            Text("Solstice+")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.solsticeTextPrimary)

            Text(context ?? "Unlock your full cycle picture — fertile window, deeper insights, and data you own.")
                .font(.body)
                .foregroundStyle(Color.solsticeTextSecondary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Privacy proof points

    private var proofPoints: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Color.solsticeLockTint)
                .accessibilityHidden(true)
            Text("No account. No cloud. Pay once if you want.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.solsticeTextSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.solsticeLockTint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Feature list

    private let features: [(String, String)] = [
        ("leaf.fill", "Fertile window & ovulation prediction"),
        ("chart.xyaxis.line", "Advanced insights — symptom & mood patterns"),
        ("heart.text.square", "Apple Health sync"),
        ("square.text.square", "Home & Lock Screen widgets"),
        ("square.and.arrow.up", "Export your data as CSV"),
        ("bell.badge", "Smart period & fertile reminders"),
    ]

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.1) { symbol, label in
                HStack(spacing: 14) {
                    Image(systemName: symbol)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.solsticeAccent)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    Text(label)
                        .font(.callout)
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.solsticeSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        VStack(spacing: 12) {
            if store.loadState == .loading && store.products.isEmpty {
                ProgressView()
                    .tint(Color.solsticeAccent)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if case .failed = store.loadState {
                VStack(spacing: 8) {
                    Text("Couldn't load plans")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.solsticeTextPrimary)
                    Button("Try Again") {
                        Task { await store.loadProducts() }
                    }
                    .font(.callout)
                    .foregroundStyle(Color.solsticeAccent)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if let annual = store.annual {
                    planCard(
                        product: annual,
                        title: "Annual",
                        subtitle: perMonthText(for: annual) ?? "Billed yearly",
                        badge: store.annualSavingsText
                    )
                }
                if let lifetime = store.lifetime {
                    planCard(
                        product: lifetime,
                        title: "Lifetime",
                        subtitle: "Pay once — it's yours",
                        badge: "Best value"
                    )
                }
                if let monthly = store.monthly {
                    planCard(
                        product: monthly,
                        title: "Monthly",
                        subtitle: "Billed monthly",
                        badge: nil
                    )
                }
            }
        }
    }

    private func planCard(product: Product, title: String, subtitle: String, badge: String?) -> some View {
        let isSelected = selectedProductID == product.id
        return Button {
            selectedProductID = product.id
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.solsticeAccent : Color.solsticeTextTertiary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Color.solsticeTextPrimary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.solsticeAccent, in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.solsticeTextSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(Color.solsticeTextPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.solsticeSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.solsticeAccent : Color.solsticeSeparator,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(product.displayPrice), \(subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Purchase button

    private var purchaseButton: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
                Task { await store.purchase(product) }
            } label: {
                ZStack {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(purchaseButtonTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
            }
            .background(Color.solsticeAccent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(store.isPurchasing || store.products.isEmpty)

            Button {
                Task { await store.restore() }
            } label: {
                Text("Restore Purchase")
                    .font(.subheadline)
                    .foregroundStyle(Color.solsticeAccent)
            }
            .frame(minHeight: 44)
            .disabled(store.isPurchasing)
        }
    }

    private var purchaseButtonTitle: String {
        if selectedProductID == StoreManager.lifetimeID { return "Unlock Forever" }
        if hasIntroOffer(selectedProductID) { return "Start 7-Day Free Trial" }
        return "Subscribe"
    }

    // MARK: - Legal

    private var legalRow: some View {
        VStack(spacing: 6) {
            Text("Payment is charged to your Apple Account. Subscriptions renew automatically unless cancelled at least 24 hours before the period ends. Manage or cancel in Settings.")
                .font(.caption2)
                .foregroundStyle(Color.solsticeTextTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://solstice.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://solstice.app/privacy")!)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.solsticeTextSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func perMonthText(for product: Product) -> String? {
        guard let subscription = product.subscription else { return nil }
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        // For an annual plan, show the effective per-month price.
        guard unit == .year else { return nil }
        let months = Decimal(12 * value)
        let perMonth = product.price / months
        let formatted = perMonth.formatted(product.priceFormatStyle)
        return "\(formatted) / month, billed yearly"
    }

    private func hasIntroOffer(_ productID: String) -> Bool {
        store.products.first { $0.id == productID }?.subscription?.introductoryOffer != nil
    }
}
