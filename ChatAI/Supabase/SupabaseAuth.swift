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

    // MARK: - Public state
    @AppStorage("sb_access_token") private var storedAccessToken: String = ""
    @AppStorage("sb_refresh_token") private var storedRefreshToken: String = ""
    @AppStorage("sb_expires_at") private var storedExpiresAt: Double = 0 // epoch seconds

    var accessToken: String? { storedAccessToken.isEmpty ? nil : storedAccessToken }
    var refreshToken: String? { storedRefreshToken.isEmpty ? nil : storedRefreshToken }
    var isAuthenticated: Bool { accessToken != nil && Date().timeIntervalSince1970 < storedExpiresAt }
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

    // MARK: - Start Google sign-in
    func startGoogleSignIn() async throws {
        let redirect = "\(redirectScheme)://\(redirectHost)"
        var comps = URLComponents(url: baseURL.appendingPathComponent("auth/v1/authorize"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirect)
        ]
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
            self.authSession?.prefersEphemeralWebBrowserSession = false
            self.authSession?.presentationContextProvider = self
            _ = self.authSession?.start()
        }
    }

    // MARK: - Handle incoming URL (from Scene/SwiftUI onOpenURL)
    func handleOpenURL(_ url: URL) {
        if url.scheme == redirectScheme { // chatai://auth-callback#access_token=...
            try? storeSession(from: url)
        }
    }

    // MARK: - Sign out
    func signOut() {
        storedAccessToken = ""
        storedRefreshToken = ""
        storedExpiresAt = 0
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
