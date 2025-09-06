//
//  EmailService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 07/09/25.
//

import Foundation
import SwiftSMTP

final class EmailService {
    static let shared = EmailService()

    private let smtp: SMTP
    private let smtpPassword: String
    private let fromUser: Mail.User

    private init() {
        // Read from Info.plist to avoid hardcoding secrets
        let info = Bundle.main.infoDictionary
        let smtpEmail = (info?["SMTP_EMAIL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let smtpPassword = (info?["SMTP_APP_PASSWORD"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Validate credentials early for clearer diagnostics
        if smtpEmail.isEmpty || smtpPassword.isEmpty {
            // Construct a dummy SMTP to keep instance non-optional; actual send will throw
            self.smtp = SMTP(hostname: "smtp.gmail.com", email: "", password: "", port: 465, tlsMode: .requireTLS)
            self.smtpPassword = ""
            self.fromUser = Mail.User(name: "ChatAI", email: "")
            return
        }

        // Configure Gmail SMTP (implicit TLS on 465 is often more reliable than STARTTLS 587 on iOS networks)
        self.smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: smtpEmail,
            password: smtpPassword,
            port: 465,
            tlsMode: .requireTLS
        )
        self.smtpPassword = smtpPassword
        self.fromUser = Mail.User(name: "ChatAI", email: smtpEmail)
    }

    @discardableResult
    func sendOTP(to recipientEmail: String, otp: String) async throws {
        // Validate credentials early for clearer diagnostics
        guard !fromUser.email.isEmpty else {
            throw NSError(domain: "EmailService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Missing SMTP_EMAIL or SMTP_APP_PASSWORD in Info.plist"])
        }
        let to = Mail.User(name: recipientEmail, email: recipientEmail)
        let subject = "Your ChatAI verification code • \(Int(Date().timeIntervalSince1970))"
        let bodyText = "Your one-time verification code is: \(otp)\n\nThis code will expire in 10 minutes. If you didn't request it, you can ignore this email.)"

        let mail = Mail(
            from: fromUser,
            to: [to],
            cc: [],
            bcc: [fromUser],
            subject: subject,
            text: bodyText
        )
        // Verbose diagnostics
        print("[EmailService] Sending OTP email...")
        print("[EmailService] From: \(fromUser.email)")
        print("[EmailService] To: \(recipientEmail)")
        print("[EmailService] Host: smtp.gmail.com Port: 465 TLS: requireTLS")

        do {
            try await smtp.send(mail)
            print("[EmailService] SMTP send succeeded (465/TLS)")
        } catch {
            let nsError = NSError(
                domain: "EmailService",
                code: -20,
                userInfo: [
                    NSLocalizedDescriptionKey: "SMTP send failed: \(error.localizedDescription)",
                    "from": fromUser.email,
                    "to": recipientEmail,
                    "host": "smtp.gmail.com",
                    "port": 465
                ]
            )
            print("[EmailService] SMTP send failed: \(error)")
            throw nsError
        }

        // Fallback test path to improve deliverability diagnostics: send a second email via 587/STARTTLS
        let smtpAlt = SMTP(
            hostname: "smtp.gmail.com",
            email: fromUser.email,
            password: smtpPassword,
            port: 587,
            tlsMode: .requireSTARTTLS
        )
        let altMail = Mail(
            from: fromUser,
            to: [to],
            cc: [],
            bcc: [fromUser],
            subject: "[ALT] " + subject,
            text: bodyText + "\n\n(Alternate route: 587/STARTTLS)"
        )
        print("[EmailService] Attempting ALT route 587/STARTTLS...")
        do {
            try await smtpAlt.send(altMail)
            print("[EmailService] ALT route send succeeded (587/STARTTLS)")
        } catch {
            print("[EmailService] ALT route send failed: \(error)")
        }
    }

    // MARK: Diagnostics
    var isConfigured: Bool { !fromUser.email.isEmpty }

    func diagnostics() -> String {
        if !isConfigured { return "SMTP not configured. Add SMTP_EMAIL and SMTP_APP_PASSWORD via xcconfig." }
        return "SMTP configured for \(fromUser.email) on smtp.gmail.com:465"
    }
}

// Simple in-memory OTP manager for this session
final class OTPManager: ObservableObject {
    static let shared = OTPManager()

    @Published private(set) var lastEmail: String?
    private var currentOTP: String?
    private var expiry: Date?
    private var lastSentAt: Date?
    private let cooldown: TimeInterval = 30

    func generateOTP() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        self.currentOTP = code
        self.expiry = Date().addingTimeInterval(10 * 60)
        return code
    }

    func send(to email: String) async throws {
        lastEmail = email
        let code = generateOTP()
        try await EmailService.shared.sendOTP(to: email, otp: code)
        lastSentAt = Date()
    }

    func verify(_ input: String) -> Bool {
        guard let code = currentOTP, let expiry = expiry, Date() <= expiry else {
            return false
        }
        let ok = (input.trimmingCharacters(in: .whitespacesAndNewlines) == code)
        if ok {
            // Invalidate after successful verification
            currentOTP = nil
            self.expiry = nil
        }
        return ok
    }

    // Resend control
    func canResend() -> Bool {
        guard let last = lastSentAt else { return true }
        return Date().timeIntervalSince(last) >= cooldown
    }

    func secondsUntilResend() -> Int {
        guard let last = lastSentAt else { return 0 }
        let remaining = cooldown - Date().timeIntervalSince(last)
        return max(0, Int(ceil(remaining)))
    }
}
