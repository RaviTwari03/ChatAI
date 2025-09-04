//
//  LoginViewa.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var isSigningIn: Bool = false
    @State private var goHome: Bool = false
    @State private var signInError: String?

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            neonBackdrop.ignoresSafeArea()

            VStack(spacing: 18) {
                // Statusbar spacing
                Spacer().frame(height: 10)

                // Top brand centered
                HStack { Spacer() }
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.white.opacity(0.9))
                    Text("ChatGPT")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 28)

                // Title
                VStack(spacing: 8) {
                    Text("Log in or sign up")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Please Enter Required details")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Email field
                TextField("Enter Address", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.32), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                // Continue button -> navigates to HomeReplicaView
                NavigationLink(destination: HomeView()) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color(red: 0.16, green: 0.46, blue: 1.0), Color(red: 0.77, green: 0.25, blue: 0.99)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                // OR separator (horizontal like screenshot)
                HStack(alignment: .center) {
                    Rectangle().fill(Color.white.opacity(0.22)).frame(height: 1)
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                    Rectangle().fill(Color.white.opacity(0.22)).frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Provider buttons stack
                VStack(spacing: 12) {
                    ProviderButton(title: "Continue with Phone", systemImage: "phone") {}
                    ProviderButton(title: "Continue with Google", systemImage: "g.circle") {
                        if !isSigningIn {
                            isSigningIn = true
                            Task {
                                do {
                                    try await SupabaseAuth.shared.startGoogleSignIn()
                                    // If we have a token after the flow, proceed to Home
                                    if SupabaseAuth.shared.isAuthenticated {
                                        await MainActor.run { goHome = true }
                                    }
                                } catch {
                                    // Show detailed error while preserving layout
                                    signInError = (error as? SupabaseAuth.AuthError)?.errorDescription ?? error.localizedDescription
                                    print("[LoginView] Sign-in error: \(signInError ?? error.localizedDescription)")
                                }
                                isSigningIn = false
                            }
                        }
                    }
                    ProviderButton(title: "Continue with Microsoft Account", systemImage: "rectangle.grid.2x2") {}
                    ProviderButton(title: "Continue with Apple", systemImage: "applelogo") {}
                }
                .padding(.horizontal, 24)

                Spacer()

                // Footer links
                HStack(spacing: 18) {
                    Text("Terms")
                    Text("|")
                        .opacity(0.5)
                    Text("Restore")
                    Text("|")
                        .opacity(0.5)
                    Text("Privacy")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.65))
                .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
        // Hidden navigation trigger on successful Google sign-in
        .background(
            NavigationLink(isActive: $goHome) { HomeView() } label: { EmptyView() }
        )
        // Non-intrusive alert for diagnostics
        .alert("Sign-in Error", isPresented: .constant(signInError != nil)) {
            Button("OK") { signInError = nil }
        } message: {
            Text(signInError ?? "")
        }
    }

    // MARK: Background
    private var neonBackdrop: some View {
        ZStack {
            // Dark vignette base
            LinearGradient(colors: [Color.black, Color(red: 0.02, green: 0.03, blue: 0.05)], startPoint: .top, endPoint: .bottom)

            // Green glow top-left
            RadialGradient(colors: [Color(red: 0.31, green: 0.77, blue: 0.38).opacity(0.5), .clear], center: .topLeading, startRadius: 40, endRadius: 420)
                .blur(radius: 18)
                .offset(x: -80, y: -140)
                .blendMode(.plusLighter)

            // Purple glow bottom-right
            RadialGradient(colors: [Color.purple.opacity(0.65), .clear], center: .bottomTrailing, startRadius: 60, endRadius: 520)
                .blur(radius: 26)
                .offset(x: 40, y: 170)
                .blendMode(.plusLighter)
        }
    }
}

// MARK: Components
private struct ProviderButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundColor(.white)
                    .frame(width: 20)
                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LoginReplicaView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
