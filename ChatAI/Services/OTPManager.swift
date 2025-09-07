//
//  OTPManager.swift
//  ChatAI
//
//  Created by Cascade on 07/09/25.
//

import Foundation

final class OTPManager {
    static let shared = OTPManager()
    private init() {}

    private struct OTPEntry {
        let code: String
        let expiresAt: Date
    }

    // Keep it in-memory; for simple 2FA this is sufficient. If you need persistence, switch to Keychain or Supabase.
    private var store: [String: OTPEntry] = [:] // key: email (lowercased)
    private let ttl: TimeInterval = 5 * 60 // 5 minutes

    func generateOTP(for email: String) -> String {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        let entry = OTPEntry(code: code, expiresAt: Date().addingTimeInterval(ttl))
        store[normalized] = entry
        return code
    }

    func verify(email: String, code: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let entry = store[normalized] else { return false }
        guard Date() <= entry.expiresAt else {
            // expired: cleanup
            store.removeValue(forKey: normalized)
            return false
        }
        let ok = entry.code == code.trimmingCharacters(in: .whitespacesAndNewlines)
        if ok {
            // one-time use
            store.removeValue(forKey: normalized)
        }
        return ok
    }

    func timeRemaining(for email: String) -> TimeInterval? {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let entry = store[normalized] else { return nil }
        return max(0, entry.expiresAt.timeIntervalSinceNow)
    }

    #if DEBUG
    // Development helper: expose current OTP for testing in DEBUG builds only.
    func currentCode(for email: String) -> String? {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store[normalized]?.code
    }
    #endif
}
