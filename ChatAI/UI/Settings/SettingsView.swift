//
//  SettingsView.swift
//  ChatAI
//
//  Created by Cascade on 11/09/25.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall: Bool = false
    @ObservedObject private var purchase = PurchaseManager.shared

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            neonBackdrop.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Pro Card
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .overlay(proCard)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)

                    // Family promo style button
                    Button { /* hook to feature later */ } label: {
                        HStack {
                            Text("Bring family conversations together")
                                .foregroundColor(.white)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.cyan, lineWidth: 1.5)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        )
                    }
                    .buttonStyle(.plain)

                    // Restore purchases row
                    HStack {
                        Text("Already Subscribed")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.footnote)
                        Spacer()
                        Button {
                            Task { await purchase.restore() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Restore purchase")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)

                    // One card containing 4 actions
                    SettingsListCard(rows: [
                        .init(icon: "star", title: "Rate ChatNow", action: { openReview() }),
                        .init(icon: "square.and.arrow.up", title: "Share", action: { shareApp() }),
                        .init(icon: "envelope", title: "Feedback & Support", action: { emailSupport() }),
                        .init(icon: "info.circle", title: "About us", action: { openURL("https://example.com/about") })
                    ])

                    Text("Legal").foregroundColor(.white.opacity(0.6)).padding(.top, 8)
                    SettingsListCard(rows: [
                        .init(icon: "doc.text", title: "Terms of Service", action: { openURL("https://example.com/terms") }),
                        .init(icon: "lock.doc", title: "Privacy Policy", action: { openURL("https://example.com/privacy") })
                    ])
                }
                .padding(16)
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) { Text("Setting").foregroundColor(.white) }
        }
        .preferredColorScheme(.dark)
        // Paywall nav
        .background(
            NavigationLink(isActive: $showPaywall) { PaywallView() } label: { EmptyView() }
        )
    }

    private var proCard: some View {
        VStack(spacing: 10) {
            Text("ChatNow Plus")
                .foregroundColor(.white)
                .font(.headline)
            Text("Unlock access to GPT-4o, Claude 3.5, higher word count limits & unlimited chats.")
                .foregroundColor(.white.opacity(0.8))
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button {
                showPaywall = true
            } label: {
                Text("Redeem Your free trial")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                        )
                    )
            }
            .buttonStyle(.plain)
            Text("3-day free trial, ₹ 699/week thereafter\nCancel anytime")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }

    // Single card list
    private struct SettingsListCard: View {
        struct Row {
            let icon: String
            let title: String
            let action: () -> Void
        }
        var rows: [Row]
        var body: some View {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    Button(action: row.action) {
                        HStack(spacing: 12) {
                            Image(systemName: row.icon)
                            Text(row.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    if idx < rows.count - 1 {
                        Divider().background(Color.white.opacity(0.15))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.03)],
                        startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var neonBackdrop: some View {
        ZStack {
            LinearGradient(colors: [Color.clear, Color.purple.opacity(0.35)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color.green.opacity(0.3), .clear], center: .topLeading, startRadius: 40, endRadius: 420)
                .blur(radius: 20)
                .offset(x: -80, y: -140)
                .blendMode(.plusLighter)
        }
    }

    private func openURL(_ s: String) {
        guard let url = URL(string: s) else { return }
        UIApplication.shared.open(url)
    }

    private func openReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func shareApp() {
        let url = URL(string: "https://example.com")!
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
    }

    private func emailSupport() {
        let email = "support@example.com"
        let subject = "ChatNow Feedback"
        let body = "Describe your issue here."
        let s = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: s) { UIApplication.shared.open(url) }
    }
}

private struct NeoGroupStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
