//
//  SupabaseAuth.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 04/09/25.
//

import Foundation
import AuthenticationServices
import SwiftUI
import UIKit

// Simple in-app session store for Supabase OAuth (Implicit grant)
// Tokens are persisted to UserDefaults for demo purposes. Consider using Keychain in production.
final class SupabaseAuth: NSObject {
    static let shared = SupabaseAuth()

    private let baseURL: URL = Secrets.supabaseUrl
    private let anonKey: String = Secrets.supabaseAnonKey

    // Your custom URL scheme must be registered in Info.plist (CFBundleURLTypes)
    // Example: chatai://auth-callback
    private let redirectScheme = "chatai"
    private let redirectHost = "auth-callback"

    private var authSession: ASWebAuthenticationSession?
    private var appleContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Diagnostics
    private func isURLSchemeRegistered(_ scheme: String) -> Bool {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else { return false }
        for item in urlTypes {
            if let schemes = item["CFBundleURLSchemes"] as? [String], schemes.contains(where: { $0.caseInsensitiveCompare(scheme) == .orderedSame }) {
                return true
            }
        }
        return false
    }

    /// Returns a multi-line diagnostics string to help troubleshoot Apple OAuth configuration.
    func diagnosticsForApple() -> String {
        let bundleID = Bundle.main.bundleIdentifier ?? "<unknown>"
        let schemeOK = isURLSchemeRegistered(redirectScheme)
        let expectedOAuthCallback = baseURL.appendingPathComponent("auth/v1/callback").absoluteString
        let now = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = []
        lines.append("Time: \(now)")
        lines.append("BundleID: \(bundleID)")
        lines.append("Supabase URL: \(baseURL.absoluteString)")
        lines.append("Expected OAuth callback: \(expectedOAuthCallback)")
        lines.append("App deep link capture: \(redirectScheme)://\(redirectHost)")
        lines.append("URL scheme registered: \(schemeOK ? "YES" : "NO")")
        lines.append("isAuthenticated: \(isAuthenticated)")
        return lines.joined(separator: "\n")
    }

    // MARK: - Public state
    @AppStorage("sb_access_token") private var storedAccessToken: String = ""
    @AppStorage("sb_refresh_token") private var storedRefreshToken: String = ""
    @AppStorage("sb_expires_at") private var storedExpiresAt: Double = 0 // epoch seconds
    @AppStorage("sb_email") private var storedEmail: String = ""

    var accessToken: String? { storedAccessToken.isEmpty ? nil : storedAccessToken }
    var refreshToken: String? { storedRefreshToken.isEmpty ? nil : storedRefreshToken }
    var isAuthenticated: Bool { accessToken != nil && Date().timeIntervalSince1970 < storedExpiresAt }
    var isLocalSession: Bool { (accessToken ?? "").hasSuffix(".local") }
    var displayName: String {
        // Try to read a friendly name from the access token (JWT) claims
        guard let token = accessToken, let claims = Self.decodeJWT(token) else { return "Guest" }
        if let userMeta = claims["user_metadata"] as? [String: Any] {
            if let full = userMeta["full_name"] as? String, !full.isEmpty { return full }
            if let name = userMeta["name"] as? String, !name.isEmpty { return name }
        }
        if let name = claims["name"] as? String, !name.isEmpty { return name }
        if let email = claims["email"] as? String, !email.isEmpty { return email }
        return "Guest"
    }

    // MARK: - Email Magic Link sign-in (Supabase-managed; creates user in Auth)
    /// Sends a Supabase-managed magic link to the given email.
    /// When the user taps the link, your onOpenURL handler will receive the callback and store the session.
    /// This will also create the user in the Supabase Auth "Users" table when they complete the flow.
    func sendMagicLink(to email: String, createUser: Bool = true) async throws {
        let redirect = "\(redirectScheme)://\(redirectHost)"
        var comps = URLComponents(url: baseURL.appendingPathComponent("auth/v1/otp"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "redirect_to", value: redirect)
        ]
        guard let url = comps.url else { throw AuthError.configurationIssue("Could not build OTP URL for magic link") }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "email": email,
            "create_user": createUser,
            "type": "magiclink"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw AuthError.configurationIssue("Magic link request failed with status \(http.statusCode). Check your Supabase URL/Anon Key and Auth settings.")
        }
        #if DEBUG
        print("[SupabaseAuth] Magic link requested for \(email).")
        #endif
        // We don't set tokens here; session is established when the user taps the magic link and returns via onOpenURL
    }

    // MARK: - Start Apple sign-in (Native) -> exchange id_token with Supabase
    func startNativeAppleSignIn() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.appleContinuation = continuation
            controller.performRequests()
        }
    }

    private func exchangeAppleIDToken(_ idToken: String) async throws {
        var comps = URLComponents(url: baseURL.appendingPathComponent("auth/v1/token"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]
        guard let url = comps.url else { throw AuthError.configurationIssue("Could not build token URL for Apple exchange") }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError.configurationIssue("Apple token exchange failed: \(http.statusCode) - \(msg)")
        }
        // Expect JSON with access_token, refresh_token, expires_in
        guard
            let obj = try? JSONSerialization.jsonObject(with: data, options: []),
            let dict = obj as? [String: Any]
        else { throw URLError(.cannotParseResponse) }
        try storeSession(from: dict)
    }
    /// Supabase user ID (UUID string), typically found in the `sub` claim of the JWT
    var userId: String? {
        guard let token = accessToken, let claims = Self.decodeJWT(token) else { return nil }
        if let sub = claims["sub"] as? String, !sub.isEmpty { return sub }
        if let uid = claims["user_id"] as? String, !uid.isEmpty { return uid }
        if let userMeta = claims["user_metadata"] as? [String: Any], let uid = userMeta["user_id"] as? String, !uid.isEmpty { return uid }
        return nil
    }
    var lastEmail: String? { storedEmail.isEmpty ? nil : storedEmail }

    // MARK: - Public error type
    enum AuthError: LocalizedError {
        case userCancelled
        case redirectMismatch
        case providerMissingSecret
        case invalidCallbackURL
        case configurationIssue(String)
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .userCancelled:
                return "Sign-in cancelled."
            case .redirectMismatch:
                return "Google rejected the request (redirect_uri_mismatch). Ensure the Google OAuth client has the redirect URI: /auth/v1/callback for your Supabase project."
            case .providerMissingSecret:
                return "Google provider is missing a Client Secret in Supabase. Add the Web application Client Secret and save."
            case .invalidCallbackURL:
                return "Invalid callback URL received from OAuth."
            case .configurationIssue(let msg):
                return msg
            case .underlying(let err):
                return err.localizedDescription
            }
        }
    }

    // MARK: - Start Apple sign-in (Supabase OAuth)
    func startAppleSignIn(preferEphemeral: Bool? = nil) async throws {
        let redirect = "\(redirectScheme)://\(redirectHost)"
        var comps = URLComponents(url: baseURL.appendingPathComponent("auth/v1/authorize"), resolvingAgainstBaseURL: false)!
        let items: [URLQueryItem] = [
            URLQueryItem(name: "provider", value: "apple"),
            URLQueryItem(name: "redirect_to", value: redirect)
        ]
        comps.queryItems = items
        guard let authURL = comps.url else { throw AuthError.configurationIssue("Could not build authorize URL for Apple") }

        // Unconditional logs to aid debugging even in Release
        NSLog("[SupabaseAuth] Opening Apple auth URL: %@", authURL.absoluteString)
        NSLog("[SupabaseAuth] Expected redirect to be: %@/auth/v1/callback -> app will capture at %@://%@", baseURL.absoluteString, redirectScheme, redirectHost)

        // Runtime check: ensure our custom URL scheme is registered in Info.plist
        if !isURLSchemeRegistered(redirectScheme) {
            let msg = "URL scheme '\(redirectScheme)' is NOT registered in Info.plist (CFBundleURLTypes). OAuth callback cannot return to the app."
            NSLog("[SupabaseAuth][ERROR] %@", msg)
            throw AuthError.configurationIssue(msg)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: self.redirectScheme) { callbackURL, error in
                if let callbackURL {
                    NSLog("[SupabaseAuth] Apple callback URL received: %@", callbackURL.absoluteString)
                }
                if let error {
                    NSLog("[SupabaseAuth] Apple OAuth session completed with error: %@", error.localizedDescription)
                }
                if let error = error as? ASWebAuthenticationSessionError {
                    switch error.code {
                    case .canceledLogin:
                        // Often shown when Apple or Supabase shows an error page and the user closes the sheet
                        let msg = "Apple sign-in didn't complete. Verify Supabase Apple provider configuration and Services ID return URL includes your Supabase callback (/auth/v1/callback)."
                        return continuation.resume(throwing: AuthError.configurationIssue(msg))
                    default:
                        return continuation.resume(throwing: AuthError.underlying(error))
                    }
                } else if let error = error {
                    return continuation.resume(throwing: AuthError.underlying(error))
                }

                guard let url = callbackURL else { return continuation.resume(throwing: AuthError.invalidCallbackURL) }
                do {
                    try self.storeSession(from: url)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            // Apple sign-in typically prefers ephemeral session for privacy, but allow override
            if let preferEphemeral { self.authSession?.prefersEphemeralWebBrowserSession = preferEphemeral }
            else { self.authSession?.prefersEphemeralWebBrowserSession = false }
            self.authSession?.presentationContextProvider = self
            let started = self.authSession?.start() ?? false
            if !started {
                NSLog("[SupabaseAuth][ERROR] ASWebAuthenticationSession failed to start. Check presentation context and scene/window availability.")
            }
        }
    }

    // MARK: - Start Google sign-in
    func startGoogleSignIn(forceAccountChooser: Bool = false, preferEphemeral: Bool? = nil, loginHint: String? = nil) async throws {
        let redirect = "\(redirectScheme)://\(redirectHost)"
        var comps = URLComponents(url: baseURL.appendingPathComponent("auth/v1/authorize"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirect)
        ]
        if forceAccountChooser {
            // Ask Google to show the account chooser instead of auto-signing with last session
            items.append(URLQueryItem(name: "prompt", value: "select_account"))
        }
        if let loginHint, !loginHint.isEmpty {
            items.append(URLQueryItem(name: "login_hint", value: loginHint))
        }
        comps.queryItems = items
        guard let authURL = comps.url else { throw AuthError.configurationIssue("Could not build authorize URL") }

        // Debug: print the exact URL we open
        #if DEBUG
        print("[SupabaseAuth] Opening auth URL: \(authURL.absoluteString)")
        print("[SupabaseAuth] Expected Google redirect to be: \(baseURL.absoluteString)/auth/v1/callback")
        #endif

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: self.redirectScheme) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError {
                    switch error.code {
                    case .canceledLogin:
                        // Most common when Google shows an error page (e.g., redirect mismatch) and the user closes the sheet.
                        // We surface a more useful message for troubleshooting.
                        return continuation.resume(throwing: AuthError.redirectMismatch)
                    default:
                        return continuation.resume(throwing: AuthError.underlying(error))
                    }
                } else if let error = error {
                    return continuation.resume(throwing: AuthError.underlying(error))
                }

                guard let url = callbackURL else { return continuation.resume(throwing: AuthError.invalidCallbackURL) }
                do {
                    try self.storeSession(from: url)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            // Default to non-ephemeral (reuse cookies). Caller can override.
            if let preferEphemeral { self.authSession?.prefersEphemeralWebBrowserSession = preferEphemeral }
            else { self.authSession?.prefersEphemeralWebBrowserSession = false }
            self.authSession?.presentationContextProvider = self
            _ = self.authSession?.start()
        }
    }

    // MARK: - Handle incoming URL (from Scene/SwiftUI onOpenURL)
    func handleOpenURL(_ url: URL) {
        if url.scheme == redirectScheme { // chatai://auth-callback#access_token=...
            NSLog("[SupabaseAuth] handleOpenURL received: %@", url.absoluteString)
            try? storeSession(from: url)
        }
    }

    // MARK: - Sign out
    func signOut() {
        storedAccessToken = ""
        storedRefreshToken = ""
        storedExpiresAt = 0
        storedEmail = ""
        
        // Post notification that auth state changed
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
        }
    }

    // MARK: - Local email authentication (for custom OTP flow)
    // Issues a lightweight pseudo-JWT so App can consider the user authenticated without Supabase OAuth.
    // Token contains {"email": email, "exp": epochSeconds}
    func authenticateLocally(email: String, expiresIn: TimeInterval = 30 * 24 * 3600) {
        let exp = Date().timeIntervalSince1970 + expiresIn
        let header = ["alg": "none", "typ": "JWT"]
        let payload: [String: Any] = ["email": email, "exp": Int(exp)]
        func b64url(_ obj: Any) -> String {
            let data = try! JSONSerialization.data(withJSONObject: obj, options: [])
            var s = data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            return s
        }
        let token = b64url(header) + "." + b64url(payload) + ".local"
        storedAccessToken = token
        storedRefreshToken = ""
        storedExpiresAt = exp
        storedEmail = email
        NSLog("[SupabaseAuth] Local email session issued for %@, exp in %ds", email, Int(expiresIn))
        // Notify the app that authentication state has changed (e.g., to refresh subscription status)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
        }
    }

    // MARK: - Private helpers
    private func storeSession(from url: URL) throws {
        // Supabase returns tokens in the URL fragment for implicit grant.
        // Example: chatai://auth-callback#access_token=...&refresh_token=...&expires_in=3600&token_type=bearer
        guard let fragment = url.fragment, !fragment.isEmpty else { throw URLError(.badServerResponse) }
        let dict = Self.parseQuery(fragment)
        guard
            let accessToken = dict["access_token"],
            let refreshToken = dict["refresh_token"],
            let expiresInStr = dict["expires_in"], let expiresIn = Double(expiresInStr)
        else { throw URLError(.cannotParseResponse) }

        storedAccessToken = accessToken
        storedRefreshToken = refreshToken
        storedExpiresAt = Date().timeIntervalSince1970 + expiresIn
        if let claims = Self.decodeJWT(accessToken), let email = claims["email"] as? String, !email.isEmpty {
            storedEmail = email
        }
        // Post notification that auth state changed for URL-based flow as well (Apple/Google OAuth callbacks)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
        }
    }

    private func storeSession(from dict: [String: Any]) throws {
        guard
            let accessToken = dict["access_token"] as? String,
            let refreshToken = dict["refresh_token"] as? String,
            let expiresIn = dict["expires_in"] as? TimeInterval
        else { throw URLError(.cannotParseResponse) }

        storedAccessToken = accessToken
        storedRefreshToken = refreshToken
        storedExpiresAt = Date().timeIntervalSince1970 + expiresIn
        if let claims = Self.decodeJWT(accessToken), let email = claims["email"] as? String, !email.isEmpty {
            storedEmail = email
            
            // Post notification that auth state changed
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .authStateChanged, object: nil)
            }
        }
    }

    private static func parseQuery(_ query: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let name = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            result[name] = value
        }
        return result
    }

    private static func decodeJWT(_ token: String) -> [String: Any]? {
        // JWT format: header.payload.signature (Base64URL)
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let payloadPart = String(parts[1])
        // Convert base64url to base64 by replacing -_/ stripping padding
        var base64 = payloadPart
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - (base64.count % 4)
        if padding < 4 { base64 += String(repeating: "=", count: padding) }
        guard let data = Data(base64Encoded: base64) else { return nil }
        guard
            let obj = try? JSONSerialization.jsonObject(with: data, options: []),
            let dict = obj as? [String: Any]
        else { return nil }
        return dict
    }
}

extension SupabaseAuth: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Try to return the key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - Native Apple Sign-in delegates
extension SupabaseAuth: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            appleContinuation?.resume(throwing: AuthError.configurationIssue("Missing Apple identity token"))
            appleContinuation = nil
            return
        }

        Task { [weak self] in
            do {
                try await self?.exchangeAppleIDToken(idToken)
                self?.appleContinuation?.resume()
            } catch {
                self?.appleContinuation?.resume(throwing: error)
            }
            self?.appleContinuation = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleContinuation?.resume(throwing: error)
        appleContinuation = nil
    }
}

extension SupabaseAuth: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
