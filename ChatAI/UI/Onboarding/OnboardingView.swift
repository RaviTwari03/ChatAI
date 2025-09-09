//
//  OnboardingView.swift
//  ChatAI
//
//  Created by Cascade on 09/09/25.
//

import SwiftUI

// MARK: - Onboarding Models
struct OnboardingPage: Identifiable {
    let id = UUID()
    let titleTop: String
    let titleHighlight: String
    let titleBottom: String
    let content: AnyView
    let showContinue: Bool
    let continueTitle: String
    let continueAction: (() -> Void)?
}

// MARK: - Onboarding Root
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var index: Int = 0
    @State private var showingPaywall: Bool = false

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                titleTop: "Ask AI Assistant  About Anything",
                titleHighlight: "  Anything",
                titleBottom: "",
                content: AnyView(FirstHeroIllustration()),
                showContinue: true,
                continueTitle: "Continue",
                continueAction: nil
            ),
            OnboardingPage(
                titleTop: "Ask AI",
                titleHighlight: " Assistant ",
                titleBottom: "About Anything",
                content: AnyView(ChatExamplesCard()),
                showContinue: true,
                continueTitle: "Continue",
                continueAction: nil
            ),
            OnboardingPage(
                titleTop: "More AI",
                titleHighlight: " Essentials ",
                titleBottom: "For You",
                content: AnyView(FeatureGrid()),
                showContinue: true,
                continueTitle: "Continue",
                continueAction: nil
            ),
            OnboardingPage(
                titleTop: "Generate More",
                titleHighlight: " AI Images ",
                titleBottom: "& Videos",
                content: AnyView(ImageGalleryMock()),
                showContinue: true,
                continueTitle: "Continue",
                continueAction: nil
            ),
            OnboardingPage(
                titleTop: "Explore Answer",
                titleHighlight: " With Chat AI ",
                titleBottom: "",
                content: AnyView(ConversationPreview()),
                showContinue: true,
                continueTitle: "Continue",
                continueAction: nil
            ),
            OnboardingPage(
                titleTop: "Be Part Of",
                titleHighlight: " Happy Community ",
                titleBottom: "",
                content: AnyView(CommunityPreview()),
                showContinue: true,
                continueTitle: "Continue",
                continueAction: nil
            ),
//            OnboardingPage(
//                titleTop: "Upgrade to",
//                titleHighlight: " Pro ",
//                titleBottom: "",
//                content: AnyView(ProBenefitsCard()),
//                showContinue: true,
//                continueTitle: "3-DAY FREE TRIAL",
//                continueAction: { NotificationCenter.default.post(name: .showPaywall, object: nil) }
//            ),
//            OnboardingPage(
//                titleTop: "Refill Your",
//                titleHighlight: " Credits ",
//                titleBottom: "",
//                content: AnyView(CreditsPreview()),
//                showContinue: true,
//                continueTitle: "Get Started",
//                continueAction: nil
//            )
        ]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            NeonBackdrop()

            VStack(spacing: 0) {
                // Title
                VStack(spacing: 6) {
                    let p = pages[index]
                    HStack(spacing: 0) {
                        Text(p.titleTop)
                        Text(p.titleHighlight).foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        Text(p.titleBottom)
                    }
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Pager
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        VStack {
                            page.content
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.horizontal, 16)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Bottom actions
                VStack(spacing: 12) {
                    Button {
                        if let action = pages[index].continueAction {
                            action()
                        }
                        goNext()
                    } label: {
                        Text(pages[index].continueTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)

                    Button {
                        skip()
                    } label: {
                        Text("Skip")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .preferredColorScheme(.dark)
    }

    private func goNext() {
        if index < pages.count - 1 {
            index += 1
        } else {
            finish()
        }
    }

    private func skip() {
        finish()
    }

    private func finish() {
        hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Backdrop
struct NeonBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.02, green: 0.03, blue: 0.05)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color.green.opacity(0.45), .clear], center: .topLeading, startRadius: 30, endRadius: 420)
                .blur(radius: 18)
                .offset(x: -80, y: -140)
                .blendMode(.plusLighter)
            RadialGradient(colors: [Color.purple.opacity(0.6), .clear], center: .bottomTrailing, startRadius: 60, endRadius: 520)
                .blur(radius: 24)
                .offset(x: 50, y: 180)
                .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Page Contents (lightweight replicas)
struct FirstHeroIllustration: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12), lineWidth: 1))
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .purple)
                        .font(.system(size: 42))
                    Text("Smart answers, creative help, and tools to boost your productivity.")
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(28)
            }
            .frame(height: 320)
            Spacer()
        }
    }
}

struct ChatExamplesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Bubble(role: .user, text: "Summarize my 10-page PDF fast")
            Bubble(role: .assistant, text: "Sure! Here's a concise summary with key points…")
            Bubble(role: .user, text: "Write a cover letter for this job")
            Bubble(role: .assistant, text: "Absolutely! I'll tailor it to your resume and role.")
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct FeatureGrid: View {
    let items: [(String, String)] = [
        ("mic.fill", "Voice Input"),
        ("photo.on.rectangle.angled", "Image Generate"),
        ("doc.text", "Document Tools"),
        ("sparkles", "Smart Prompts"),
        ("bolt.fill", "Fast Replies"),
        ("lock.shield", "Private by Design")
    ]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(0..<items.count, id: \.self) { i in
                let it = items[i]
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.14), lineWidth: 1))
                    .overlay(
                        HStack(spacing: 12) {
                            Image(systemName: it.0).foregroundColor(.white)
                            Text(it.1).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(14)
                    )
                    .frame(height: 64)
            }
        }
        .padding(.vertical, 10)
    }
}

struct ImageGalleryMock: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                GalleryTile(color: .orange)
                GalleryTile(color: .blue)
            }
            HStack(spacing: 12) {
                GalleryTile(color: .purple)
                GalleryTile(color: .green)
            }
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct GalleryTile: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(color.opacity(0.3).gradient)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12), lineWidth: 1))
            .frame(height: 140)
    }
}

struct ConversationPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Bubble(role: .user, text: "Explain quantum computing in simple terms")
            Bubble(role: .assistant, text: "Quantum computers use qubits that can be 0 and 1 at the same time…")
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct CommunityPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach(0..<4) { _ in
                    Circle().fill(.blue.opacity(0.3)).frame(width: 40, height: 40)
                }
            }
            Text("Join creators and learners discovering AI together.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct ProBenefitsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BenefitRow(text: "Latest AI technology access")
            BenefitRow(text: "Faster, higher priority responses")
            BenefitRow(text: "Unlock image generation & voice")
            BenefitRow(text: "Use longer prompts & context")
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct BenefitRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
            Text(text).foregroundColor(.white)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

//struct CreditsPreview: View {
//    var body: some View {
//        HStack(spacing: 12) {
//            CreditCard(title: "Basic", credits: 100)
//            CreditCard(title: "Plus", credits: 300)
//            CreditCard(title: "Max", credits: 1000)
//        }
//        .padding(.top, 10)
//    }
//}

//struct CreditCard: View {
//    let title: String
//    let credits: Int
//    var body: some View {
//        VStack(spacing: 6) {
//            Text(title).foregroundColor(.white.opacity(0.8)).font(.caption)
//            Text("\(credits)")
//                .font(.headline)
//                .foregroundColor(.white)
//            Text("credits").foregroundColor(.white.opacity(0.6)).font(.caption2)
//        }
//        .padding(14)
//        .frame(maxWidth: .infinity)
//        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.03)))
//        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12), lineWidth: 1))
//    }


// MARK: - Bubble
struct Bubble: View {
    enum Role { case user, assistant }
    let role: Role
    let text: String
    var body: some View {
        HStack(alignment: .bottom) {
            if role == .assistant { Circle().fill(.purple).frame(width: 8, height: 8).offset(y: 6) }
            Text(text)
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(role == .user ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
                )
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.16), lineWidth: 1))
            if role == .user { Circle().fill(.blue).frame(width: 8, height: 8).offset(y: 6) }
            Spacer(minLength: 0)
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}
#endif
