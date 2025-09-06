//
//  PaywallView.swift
//  ChatAI
//
//  Created by Cascade on 06/09/2025.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var freeTrialEnabled: Bool = true
    @State private var selectedPlan: Plan = .yearly

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top icon
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .leading, endPoint: .trailing))
                    .padding(.top, 24)

                // Title
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Upgrade to")
                            .foregroundColor(.white)
                        Text("Pro")
                            .foregroundStyle(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing))
                    }
                    .font(.system(size: 34, weight: .bold))
                }
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

                // Toggle card (compact)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        HStack {
                            Text("Free trial enabled")
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Spacer()
                            Toggle("", isOn: $freeTrialEnabled)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .frame(height: 56)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // Plans
                VStack(spacing: 12) {
                    planCard(
                        title: "YEARLY ACCESS",
                        subtitle: "Just ₹ 3,450.00 per year",
                        priceNote: "79.15/Week",
                        badge: "Best Offer",
                        isSelected: selectedPlan == .yearly
                    ) { selectedPlan = .yearly }

                    planCard(
                        title: "3-DAY FREE TRIAL",
                        subtitle: "Then ₹ 599.00",
                        priceNote: "Per week",
                        badge: nil,
                        isSelected: selectedPlan == .weekly
                    ) { selectedPlan = .weekly }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer(minLength: 0)

                // Continue button
                Button(action: {
                    // Hook up to StoreKit purchase flow later
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Footer links
                HStack(spacing: 22) {
                    Button("Terms") { }
                    Button("Restore") { }
                    Button("Privacy") { }
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Components
    private func featureRow(symbol: String, color: Color, text: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: symbol)
                .foregroundColor(color)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
        }
    }

    private func planCard(title: String, subtitle: String, priceNote: String, badge: String?, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing), lineWidth: 1.2)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundColor(.white)
                            .font(.subheadline).bold()
                        Text(subtitle)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.caption)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(priceNote)
                            .foregroundColor(.white)
                            .font(.footnote)
                    }
                }
                .padding(14)

                if let badge = badge {
                    Text(badge)
                        .font(.caption2).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        )
                        .offset(x: -12, y: -12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72)
        }
        .buttonStyle(.plain)
    }

    enum Plan { case yearly, weekly }
}

#Preview {
    NavigationStack { PaywallView() }
}
