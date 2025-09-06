
import SwiftUI
import StoreKit

struct PaywallView: View {
    // Use the shared manager
    @StateObject private var purchases = PurchaseManager.shared

    // UI state
    @State private var freeTrialEnabled: Bool = true
    @State private var selectedPlan: Plan = .yearly
    @State private var isProcessing: Bool = false
    @State private var errorText: String?

    enum Plan { case yearly, monthly, weekly }

    // Map selected plan to your product IDs from App Store Connect
    private var selectedProduct: Product? {
        switch selectedPlan {
        case .yearly:
            // Prefer Yearly; if unavailable, fall back to Monthly.
            return purchases.products.first(where: { $0.id == "c_ca_5900" })
                ?? purchases.products.first(where: { $0.id == "c_ca_1299" })
        case .monthly:
            return purchases.products.first(where: { $0.id == "c_ca_1299" })
        case .weekly:
            return purchases.products.first(where: { $0.id == "c_ca_699" })
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Icon + Title
                    Image(systemName: "sparkles")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .leading, endPoint: .trailing))
                        .padding(.top, 24)

                    HStack(spacing: 6) {
                        Text("Upgrade to").foregroundColor(.white)
                        Text("Pro")
                            .foregroundStyle(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing))
                    }
                    .font(.system(size: 34, weight: .bold))
                    .padding(.top, 10)

                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        featureRow(symbol: "lightbulb", color: .orange, text: "Smarter AI Technology")
                        featureRow(symbol: "wand.and.stars", color: .yellow, text: "Unlimited image generate")
                        featureRow(symbol: "doc.text.magnifyingglass", color: .cyan, text: "Doc Insights Made Easy")
                        featureRow(symbol: "message.badge.waveform.fill", color: .green, text: "Unlimited image generate")
                    }
                    .padding(.top, 22)
                    .padding(.horizontal, 20)

                    // Free trial toggle (compact)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            HStack {
                                Text("Free trial enabled")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                Spacer()
                                Toggle("", isOn: $freeTrialEnabled).labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .frame(height: 56)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Plan cards
                    VStack(spacing: 12) {
                        planCard(
                            title: "YEARLY ACCESS",
                            subtitle: "Just ₹ 5,900.00 per year",
                            priceNote: "₹ 113.45/Week",
                            badge: "Best Offer",
                            isSelected: selectedPlan == .yearly
                        ) { selectedPlan = .yearly }

                        planCard(
                            title: "MONTHLY ACCESS",
                            subtitle: "Just ₹ 1,299.00 per month",
                            priceNote: "₹ 324.75/Week",
                            badge: nil,
                            isSelected: selectedPlan == .monthly
                        ) { selectedPlan = .monthly }

                        planCard(
                            title: "3-DAY FREE TRIAL",
                            subtitle: "Then ₹ 699.00 per week",
                            priceNote: "₹ 174/Week",
                            badge: nil,
                            isSelected: selectedPlan == .weekly
                        ) { selectedPlan = .weekly }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    if let errorText {
                        Text(errorText)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }

                    // Diagnostic surface for StoreKit issues
                    if let skError = purchases.lastStoreKitError {
                        Text("StoreKit: \(skError)")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }
                    #if DEBUG
//                    Group {
//                        Text("Debug: \(purchases.debugSummary)")
//                            .foregroundColor(.white.opacity(0.7))
//                            .font(.caption2)
//                            .padding(.horizontal, 20)
//                            .padding(.top, 2)
//                    }
                    #endif

                    // Continue -> triggers StoreKit purchase sheet
                    Button {
                        Task { await onContinue() }
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing { ProgressView().tint(.white) }
                            Text("Continue").font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Footer
                    HStack(spacing: 22) {
                        Button("Terms") { }
                        Button("Restore") { Task { await purchases.restore() } }
                        Button("Privacy") { }
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Ensure products load when paywall opens
            purchases.start()
            await purchases.refreshProductsAndEntitlements()
            #if DEBUG
            print("[Paywall] Appeared. Products count: \(purchases.products.count), IDs: \(purchases.products.map{ $0.id })")
            #endif
        }
    }

    // MARK: - Actions
    private func onContinue() async {
        // Ensure we have a product. If not, try to refresh once.
        var product = selectedProduct
        if product == nil {
            await purchases.refreshProductsAndEntitlements()
            product = selectedProduct
        }

        guard let chosen = product else {
            errorText = "Products not available yet. Please check your network or try again shortly."
            return
        }

        isProcessing = true
        defer { isProcessing = false }
        let ok = await purchases.purchase(chosen)
        if !ok {
            errorText = purchases.statusMessage.isEmpty ? "Purchase was not completed." : purchases.statusMessage
        } else {
            errorText = nil
        }
        #if DEBUG
        print("[Paywall] Purchase result = \(ok), status=\(purchases.statusMessage)")
        #endif
    }

    // MARK: - Subviews
    private func featureRow(symbol: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundColor(color)
            Text(text).foregroundColor(.white).font(.subheadline)
            Spacer()
        }
    }

    private func planCard(
        title: String,
        subtitle: String,
        priceNote: String,
        badge: String?,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06))
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                                       : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1.2)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).foregroundColor(.white).font(.subheadline).bold()
                        Text(subtitle).foregroundColor(.white.opacity(0.75)).font(.caption)
                    }
                    Spacer()
                    Text(priceNote).foregroundColor(.white).font(.footnote)
                }
                .padding(14)

                if let badge = badge {
                    Text(badge)
                        .font(.caption2).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)))
                        .offset(x: -12, y: -12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72)
        }
        .buttonStyle(.plain)
    }
}
