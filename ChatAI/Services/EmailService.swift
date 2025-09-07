//
//  EmailService.swift
//  ChatAI
//
//  Created by Cascade on 07/09/25.
//

import Foundation
import SwiftSMTP

struct SMTPConfig {
    let host: String
    let email: String
    let password: String
    let port: Int
    let useTLS: Bool

    init?() {
        guard
            let dict = Bundle.main.infoDictionary,
            let host = dict["SMTP_HOST"] as? String, !host.isEmpty,
            let email = dict["SMTP_EMAIL"] as? String, !email.isEmpty,
            let password = dict["SMTP_PASSWORD"] as? String, !password.isEmpty
        else { return nil }
        self.host = host
        self.email = email
        self.password = password
        self.port = (dict["SMTP_PORT"] as? String).flatMap(Int.init) ?? (dict["SMTP_PORT"] as? Int) ?? 587
        // Accept string or bool; default to TRUE if unset or unresolved placeholder
        if let raw = dict["SMTP_TLS"] as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.contains("$(") {
                // Unresolved placeholder or empty -> default TRUE
                #if DEBUG
                if trimmed.contains("$(") { print("[EmailService] WARNING: SMTP_TLS placeholder not resolved. Defaulting to TLS=YES") }
                #endif
                self.useTLS = true
            } else {
                let lowered = trimmed.lowercased()
                self.useTLS = ["1","true","yes","y"].contains(lowered)
            }
        } else if let rawB = dict["SMTP_TLS"] as? Bool {
            self.useTLS = rawB
        } else {
            self.useTLS = true
        }
    }
}

final class EmailService {
    private let smtp: SMTP
    private let fromUser: Mail.User
    private let configuredPort: Int

    init?() {
        guard let cfg = SMTPConfig() else { return nil }
        self.smtp = SMTP(
            hostname: cfg.host,
            email: cfg.email,
            password: cfg.password,
            port: Int32(cfg.port),
            tlsMode: cfg.useTLS ? .requireSTARTTLS : .ignoreTLS
        )
        self.fromUser = Mail.User(name: "ChatAI", email: cfg.email)
        self.configuredPort = cfg.port
        #if DEBUG
        print("[EmailService] SMTP config — host: \(cfg.host), email: \(cfg.email), port: \(cfg.port), TLS: \(cfg.useTLS ? "YES" : "NO")")
        #endif
    }

    struct SendOutcome {
        let ok: Bool
        let details: String?
    }

    func sendEmail(to recipient: String, subject: String, body: String) async -> Bool {
        let to = Mail.User(name: recipient, email: recipient)
        let mail = Mail(from: fromUser, to: [to], subject: subject, text: body)
        do {
            try await smtp.send(mail)
            print("[EmailService] Email sent to \(recipient)")
            return true
        } catch {
            print("[EmailService] Failed: \(error.localizedDescription)")
            return false
        }
    }

    // Verbose variant, returns diagnostics helpful for UI alerts/logs
    func sendEmailVerbose(to recipient: String, subject: String, body: String) async -> SendOutcome {
        let to = Mail.User(name: recipient, email: recipient)
        let mail = Mail(from: fromUser, to: [to], subject: subject, text: body)
        do {
            try await smtp.send(mail)
            return SendOutcome(ok: true, details: nil)
        } catch {
            // Common hints for Gmail SMTP
            let hint = "Check SMTP_HOST/EMAIL/PASSWORD, allow App Passwords, and ensure network allows SMTP port \(configuredPort)."
            let details = "\(error.localizedDescription). \(hint)"
            return SendOutcome(ok: false, details: details)
        }
    }

    func sendOTP(to email: String, code: String) async -> Bool {
        let subject = "Your ChatAI verification code"
        let body = "Your one-time verification code is: \n\n\(code)\n\nThis code will expire in 5 minutes. If you didn't request this, you can ignore this email."
        return await sendEmail(to: email, subject: subject, body: body)
    }

    func sendOTPVerbose(to email: String, code: String) async -> SendOutcome {
        let subject = "Your ChatAI verification code"
        let body = "Your one-time verification code is: \n\n\(code)\n\nThis code will expire in 5 minutes. If you didn't request this, you can ignore this email."
        return await sendEmailVerbose(to: email, subject: subject, body: body)
    }
}
