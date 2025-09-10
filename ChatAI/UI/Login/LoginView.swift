//
//  LoginViewa.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
import Combine
import UIKit

struct LoginView: View {
    @State private var email: String = ""
    @State private var isSigningIn: Bool = false
    @State private var goHome: Bool = false
    @State private var signInError: String?
    // Alert state
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    // OTP flow state
    @State private var showingOTPSheet: Bool = false
    @State private var otpCode: String = ""
    @State private var isSendingOTP: Bool = false
    @State private var isVerifyingOTP: Bool = false
    // Email captured at the time OTP is sent
    @State private var sentToEmail: String? = nil

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
                    Text("Chatly-Chatbox AI")
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

                // Continue button -> Supabase Magic Link (creates user in Supabase Auth)
                Button {
                    guard !isSigningIn else { return }
                    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard isValidEmail(trimmed) else {
                        alertTitle = "Invalid email"
                        alertMessage = "Please enter a valid email address."
                        showAlert = true
                        return
                    }
                    isSigningIn = true
                    Task {
                        print("[LoginView] Requesting Supabase magic link for: \(trimmed)")
                        do {
                            try await SupabaseAuth.shared.sendMagicLink(to: trimmed)
                            await MainActor.run {
                                alertTitle = "Check your email"
                                alertMessage = "We sent you a secure sign-in link. Open it on this device to complete sign-in."
                                showAlert = true
                                isSigningIn = false
                                sentToEmail = trimmed
                            }
                        } catch {
                            await MainActor.run {
                                alertTitle = "Could not send sign-in link"
                                alertMessage = (error as? SupabaseAuth.AuthError)?.errorDescription ?? error.localizedDescription
                                showAlert = true
                                isSigningIn = false
                                print("[LoginView] Magic link request failed: \(alertMessage)")
                            }
                        }
                    }
                } label: {
                    HStack {
                        if isSigningIn { ProgressView().tint(.white) }
                        Text(isSigningIn ? "Sending..." : "Continue")
                            .font(.headline)
                    }
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
//                    ProviderButton(title: "Continue with Phone", systemImage: "phone") {}
                    ProviderButton(title: "Continue with Google", systemImage: "g.circle") {
                        if !isSigningIn {
                            isSigningIn = true
                            Task {
                                do {
                                    // Quick SSO (no prompt) on normal tap; pass lastEmail as login_hint if available
                                    try await SupabaseAuth.shared.startGoogleSignIn(loginHint: SupabaseAuth.shared.lastEmail)
                                    // If we have a token after the flow, proceed to Home
                                    if SupabaseAuth.shared.isAuthenticated {
                                        await MainActor.run { goHome = true }
                                    }
                                } catch {
                                    // Show detailed error while preserving layout
                                    signInError = (error as? SupabaseAuth.AuthError)?.errorDescription ?? error.localizedDescription
                                    print("[LoginView] Sign-in error: \(signInError ?? error.localizedDescription)")
                                    alertTitle = "Sign-in failed"
                                    alertMessage = signInError ?? "Unknown error"
                                    showAlert = true
                                }
                                isSigningIn = false
                            }
                        }
                    }
                    // Long-press to force Google account chooser (no auto-login)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                        if !isSigningIn {
                            isSigningIn = true
                            Task {
                                do {
                                    // Force chooser but keep non-ephemeral so existing cookies allow password-less selection
                                    try await SupabaseAuth.shared.startGoogleSignIn(forceAccountChooser: true, preferEphemeral: false)
                                    if SupabaseAuth.shared.isAuthenticated {
                                        await MainActor.run { goHome = true }
                                    }
                                } catch {
                                    signInError = (error as? SupabaseAuth.AuthError)?.errorDescription ?? error.localizedDescription
                                    print("[LoginView] Sign-in error (forced chooser): \(signInError ?? error.localizedDescription)")
                                    alertTitle = "Sign-in failed"
                                    alertMessage = signInError ?? "Unknown error"
                                    showAlert = true
                                }
                                isSigningIn = false
                            }
                        }
                    })
//                    ProviderButton(title: "Continue with Microsoft Account", systemImage: "rectangle.grid.2x2") {}
                    ProviderButton(title: "Continue with Apple", systemImage: "applelogo") {
                        if !isSigningIn {
                            isSigningIn = true
                            Task {
                                do {
                                    // Use Supabase OAuth (ASWebAuthenticationSession). Non-ephemeral improves reliability.
                                    print("[LoginView] Starting Apple OAuth sign-in (non-ephemeral)")
                                    try await SupabaseAuth.shared.startAppleSignIn(preferEphemeral: false)
                                    // Wait briefly for callback to store session
                                    var authed = SupabaseAuth.shared.isAuthenticated
                                    if !authed {
                                        for attempt in 1...10 { // ~2s total
                                            try? await Task.sleep(nanoseconds: 200_000_000)
                                            authed = SupabaseAuth.shared.isAuthenticated
                                            print("[LoginView] Post-Apple callback auth check #\(attempt): \(authed)")
                                            if authed { break }
                                        }
                                    }
                                    if authed {
                                        await MainActor.run { goHome = true }
                                    } else {
                                        let hint = "Ensure Redirect URL is allowed in Supabase (/auth/v1/callback under your project URL) and app URL Scheme is configured (chatai)."
                                        let diags = SupabaseAuth.shared.diagnosticsForApple()
                                        signInError = "Apple sign-in did not complete.\n\n" + hint + "\n\nDiagnostics:\n" + diags
                                        print("[LoginView] Apple sign-in completed without tokens. \(hint)\n\nDIAGS:\n\(diags)")
                                        alertTitle = "Sign-in didn't complete"
                                        alertMessage = signInError ?? "Unknown issue"
                                        showAlert = true
                                    }
                                } catch {
                                    // If OAuth flow fails, surface message
                                    let base = (error as? SupabaseAuth.AuthError)?.errorDescription ?? error.localizedDescription
                                    let diags = SupabaseAuth.shared.diagnosticsForApple()
                                    signInError = base + "\n\nDiagnostics:\n" + diags
                                    print("[LoginView] Apple OAuth sign-in error: \(base)\n\nDIAGS:\n\(diags)")
                                    alertTitle = "Sign-in failed"
                                    alertMessage = signInError ?? "Unknown error"
                                    showAlert = true
                                }
                                isSigningIn = false
                            }
                        }
                    }
                    // Long-press the Apple button to try native sign-in (optional)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                        if !isSigningIn {
                            isSigningIn = true
                            Task {
                                do {
                                    try await SupabaseAuth.shared.startNativeAppleSignIn()
                                    if SupabaseAuth.shared.isAuthenticated { await MainActor.run { goHome = true } }
                                } catch {
                                    // Silent fallback; native may fail if entitlement/capability is missing
                                    print("[LoginView] Native Apple sign-in fallback failed: \(error.localizedDescription)")
                                }
                                isSigningIn = false
                            }
                        }
                    })
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
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // If we already have a valid session, skip login UI
            if SupabaseAuth.shared.isAuthenticated {
                goHome = true
            }
        }
        // Log when global auth state changes (helps verify OTP auth path)
        .onReceive(NotificationCenter.default.publisher(for: .authStateChanged)) { _ in
            let status = SupabaseAuth.shared.isAuthenticated ? "AUTHENTICATED" : "NOT AUTHENTICATED"
            print("[LoginView] Received authStateChanged notification -> \(status). Email=\(SupabaseAuth.shared.lastEmail ?? "<none>")")
            if SupabaseAuth.shared.isAuthenticated {
                print("[LoginView] Navigating to Home due to authenticated state.")
                goHome = true
            }
        }
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Copy Details") {
                var payload = alertTitle + "\n\n" + (alertMessage)
                UIPasteboard.general.string = payload
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // Supabase magic link flow: no OTP sheet; session will be stored when the user returns via redirect
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

// MARK: - Helpers & OTP Sheet
private extension LoginView {
    func isValidEmail(_ s: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    func format(seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct OTPSheet: View {
    let email: String
    @Binding var isPresented: Bool
    var onVerified: () -> Void

    @State private var code: String = ""
    @State private var isVerifying: Bool = false
    @State private var errorText: String?
    @State private var infoText: String?
    // Countdown to OTP expiry (5 min default, read from manager if available)
    @State private var expiryRemaining: Int = 300
    // Cooldown before allowing resend
    @State private var resendCooldown: Int = 30
    @State private var isResending: Bool = false
    @State private var timer: Timer?

    private func format(seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter verification code")
                .font(.headline)
            Text("We sent a code to \(email)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let infoText { Text(infoText).foregroundColor(.green).font(.footnote) }
#if DEBUG
            if let devCode = OTPManager.shared.currentCode(for: email) {
                Text("DEV OTP: \(devCode)")
                    .font(.footnote)
                    .foregroundColor(.yellow)
            }
#endif
            TextField("6-digit code", text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
            if let errorText { Text(errorText).foregroundColor(.red).font(.footnote) }
            HStack {
                Image(systemName: "clock")
                Text("Code expires in \(format(seconds: expiryRemaining))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            Button {
                guard !isVerifying else { return }
                // Basic client-side validation for OTP format
                let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count == 6, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmed)) else {
                    errorText = "Please enter the 6-digit code."
                    return
                }
                isVerifying = true
                Task { @MainActor in
                    print("[OTPSheet] Verifying OTP for email=\(email). EnteredCode=\(trimmed)")
                    let ok = OTPManager.shared.verify(email: email, code: trimmed)
                    print("[OTPSheet] OTP verification result: \(ok ? "SUCCESS" : "FAIL").")
                    if ok {
                        // Establish an authenticated session for the verified email
                        SupabaseAuth.shared.authenticateLocally(email: email)
                        // Double-check that the session is actually established before proceeding
                        if SupabaseAuth.shared.isAuthenticated {
                            print("[OTPSheet] Local session established. Proceeding to dismiss and navigate home.")
                            isPresented = false
                            onVerified()
                        } else {
                            print("[OTPSheet] Local session NOT established immediately. Will retry briefly...")
                            var established = SupabaseAuth.shared.isAuthenticated
                            if !established {
                                for attempt in 1...5 {
                                    try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
                                    established = SupabaseAuth.shared.isAuthenticated
                                    print("[OTPSheet] Re-check isAuthenticated attempt #\(attempt): \(established)")
                                    if established { break }
                                }
                            }
                            if established {
                                print("[OTPSheet] Local session established after retry. Proceeding.")
                                isPresented = false
                                onVerified()
                            } else {
                                print("[OTPSheet] Local session still NOT established after retries.")
                                errorText = "Failed to establish session. Please try again."
                            }
                        }
                    } else {
                        print("[OTPSheet] Invalid or expired code.")
                        errorText = "Invalid or expired code."
                    }
                    isVerifying = false
                }
            } label: {
                HStack {
                    if isVerifying { ProgressView().tint(.white) }
                    Text(isVerifying ? "Verifying..." : "Verify")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(10)
            }

            // Resend section
            VStack(spacing: 6) {
                Button {
                    guard !isResending, resendCooldown <= 0 else { return }
                    isResending = true
                    errorText = nil
                    infoText = nil
                    Task {
                        let newCode = OTPManager.shared.generateOTP(for: email)
                        if let svc = EmailService() {
                            let outcome = await svc.sendOTPVerbose(to: email, code: newCode)
                            await MainActor.run {
                                if outcome.ok {
                                    infoText = "New code sent."
                                    resendCooldown = 30
                                    // reset expiry based on manager state
                                    if let rem = OTPManager.shared.timeRemaining(for: email) {
                                        expiryRemaining = Int(rem)
                                    } else {
                                        expiryRemaining = 300
                                    }
                                } else {
                                    errorText = outcome.details ?? "Failed to resend code."
                                }
                                isResending = false
                            }
                        } else {
                            await MainActor.run {
                                errorText = "SMTP not configured."
                                isResending = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isResending { ProgressView().scaleEffect(0.7) }
                        Text(resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend code")
                    }
                }
                .disabled(resendCooldown > 0 || isResending)
                .buttonStyle(.plain)
                .foregroundColor(resendCooldown > 0 ? .gray : .white)
                .padding(.top, 2)
            }
        }
        .padding(24)
        .onAppear {
            // Initialize expiry from manager if available
            if let rem = OTPManager.shared.timeRemaining(for: email) {
                expiryRemaining = Int(rem)
            }
            // Start a 1-second timer for countdowns
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if expiryRemaining > 0 { expiryRemaining -= 1 }
                if resendCooldown > 0 { resendCooldown -= 1 }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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
            ZStack(alignment: .topLeading) {
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
        }
        .buttonStyle(.plain)
    }
}

struct LoginReplicaView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
