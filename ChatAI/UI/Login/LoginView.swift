//
//  LoginViewa.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LoginView: View {
    @State private var email: String = ""
    @State private var isSigningIn: Bool = false
    @State private var goHome: Bool = false
    @State private var signInError: String?
    // Alert state
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    // OTP state
    @State private var isSendingOTP: Bool = false
    @State private var showOTPSheet: Bool = false
    @State private var otpInput: String = ""
    // Name collection state
    @State private var showNameSheet: Bool = false
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSavingName: Bool = false

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

                // Continue button -> send OTP then prompt for code
                Button(action: {
                    guard !isSendingOTP else { return }
                    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, trimmed.contains("@"), trimmed.contains(".") else {
                        alertTitle = "Invalid email"
                        alertMessage = "Please enter a valid email address."
                        showAlert = true
                        return
                    }
                    isSendingOTP = true
                    Task {
                        do {
                            try await OTPManager.shared.send(to: trimmed)
                            await MainActor.run {
                                isSendingOTP = false
                                showOTPSheet = true
                            }
                        } catch {
                            await MainActor.run {
                                isSendingOTP = false
                                alertTitle = "Failed to send code"
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                        }
                    }
                }) {
                    HStack {
                        if isSendingOTP { ProgressView().tint(.white) }
                        Text(isSendingOTP ? "Sending..." : "Continue")
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
                    ProviderButton(title: "Continue with Apple", systemImage: "applelogo") {
                        if !isSigningIn {
                            isSigningIn = true
                            Task {
                                do {
                                    // Native Apple sign-in using ASAuthorizationAppleIDProvider
                                    try await SupabaseAuth.shared.startNativeAppleSignIn()
                                    if SupabaseAuth.shared.isAuthenticated {
                                        await MainActor.run { goHome = true }
                                    }
                                } catch {
                                    signInError = (error as? SupabaseAuth.AuthError)?.errorDescription ?? error.localizedDescription
                                    print("[LoginView] Apple sign-in error: \(signInError ?? error.localizedDescription)")
                                    alertTitle = "Sign-in failed"
                                    alertMessage = signInError ?? "Unknown error"
                                    showAlert = true
                                }
                                isSigningIn = false
                            }
                        }
                    }
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
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showOTPSheet) {
            OTPSheet(email: email, otpInput: $otpInput, onVerify: {
                let ok = OTPManager.shared.verify(otpInput)
                if ok {
                    // After OTP, go to name collection
                    showOTPSheet = false
                    showNameSheet = true
                } else {
                    alertTitle = "Invalid code"
                    alertMessage = "The code you entered is incorrect or has expired."
                    showAlert = true
                }
            }, onResend: {
                guard OTPManager.shared.canResend() else { return }
                Task { try? await OTPManager.shared.send(to: email) }
            })
            .modifier(PageDetents())
        }
        .sheet(isPresented: $showNameSheet) {
            NameSheet(firstName: $firstName, lastName: $lastName, isSaving: $isSavingName, onSave: {
                guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty,
                      !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
                    alertTitle = "Missing details"
                    alertMessage = "Please enter your first and last name."
                    showAlert = true
                    return
                }
                isSavingName = true
                Task {
                    let svc = SupabaseService()
                    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    let result = await svc.upsertAppUser(email: trimmedEmail, firstName: firstName, lastName: lastName, authId: SupabaseAuth.shared.userId)
                    await MainActor.run {
                        isSavingName = false
                        switch result {
                        case .success:
                            showNameSheet = false
                            goHome = true
                        case .failure(let err):
                            alertTitle = "Failed to save profile"
                            alertMessage = err.localizedDescription
                            showAlert = true
                        }
                    }
                }
            })
            .modifier(PageDetents())
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

// MARK: Name Sheet
private struct NameSheet: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var isSaving: Bool
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 6)

            VStack(spacing: 12) {
                Text("Set up your profile")
                    .font(.title3).bold()
                    .foregroundColor(.white)

                VStack(spacing: 10) {
                    TextField("First name", text: $firstName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                    TextField("Last name", text: $lastName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }

                Button(action: { if !isSaving { onSave() } }) {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Saving..." : "Continue")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(red: 0.16, green: 0.46, blue: 1.0), Color(red: 0.77, green: 0.25, blue: 0.99)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .opacity(isSaving ? 0.8 : 1.0)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

            Spacer(minLength: 8)
        }
        .padding(18)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: Page Sheet detents helper
private struct PageDetents: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

// MARK: OTP Sheet
private struct OTPSheet: View {
    var email: String
    @Binding var otpInput: String
    var onVerify: () -> Void
    var onResend: () -> Void

    @State private var errorText: String? = nil
    @State private var tick: Int = 0

    private var maskedEmail: String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return email }
        let name = String(parts[0])
        let domain = String(parts[1])
        let head = name.prefix(2)
        return head + String(repeating: "•", count: max(0, name.count - 2)) + "@" + domain
    }

    private var canVerify: Bool { otpInput.filter({ $0.isNumber }).count == 6 }

    var body: some View {
        VStack(spacing: 18) {
            // Grabber
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 6)

            // Card
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Verify your email")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                    Text("Code sent to \(maskedEmail)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }

                CodeInput(text: $otpInput)

                if let errorText { Text(errorText).font(.footnote).foregroundColor(.red).transition(.opacity) }

                Button(action: {
                    if canVerify {
                        onVerify()
                    } else {
                        errorText = "Enter the 6-digit code"
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                }) {
                    Text("Verify")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color(red: 0.16, green: 0.46, blue: 1.0), Color(red: 0.77, green: 0.25, blue: 0.99)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .opacity(canVerify ? 1 : 0.7)
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Text("Didn't get the code?")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.footnote)
                    Button(action: {
                        if OTPManager.shared.canResend() {
                            onResend()
                            errorText = nil
                            #if canImport(UIKit)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            #endif
                        }
                    }) {
                        let secs = OTPManager.shared.secondsUntilResend()
                        Text(OTPManager.shared.canResend() ? "Resend" : "Resend in \(secs)s")
                            .font(.footnote).bold()
                            .foregroundColor(OTPManager.shared.canResend() ? Color.blue : Color.gray)
                    }
                    .disabled(!OTPManager.shared.canResend())
                }
                .padding(.top, 4)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

            Spacer(minLength: 8)
        }
        .padding(18)
        .background(Color.black.ignoresSafeArea())
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            tick += 1
        }
    }
}

// 6-digit code input with boxes
private struct CodeInput: View {
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            // Hidden field to capture numeric input
            TextField("", text: Binding(
                get: { text },
                set: { newVal in
                    let filtered = newVal.filter({ $0.isNumber })
                    text = String(filtered.prefix(6))
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .frame(width: 0, height: 0)
            .opacity(0.01)
            .focused($focused)

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { idx in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                        Text(character(at: idx))
                            .font(.title2).monospacedDigit()
                            .foregroundColor(.white)
                    }
                    .frame(height: 48)
                }
            }
            .onTapGesture { focused = true }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true } }
    }

    private func character(at index: Int) -> String {
        let chars = Array(text)
        if index < chars.count { return String(chars[index]) }
        return ""
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
