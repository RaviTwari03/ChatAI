//
//  XAIService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 04/09/25.
//

import Foundation

struct XAIError: Error, Decodable { let message: String }

final class XAIService: ImageGenerationService {
    static let shared = XAIService()
    private init() {}

    // Use secure APIManager for API key access
    private var apiKey: String {
        do {
            return try APIManager.shared.getValidatedXAIKey()
        } catch {
            fatalError("xAI API key error: \(error.localizedDescription). Please check your Secrets.xcconfig file.")
        }
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [[String: String]]
        let stream: Bool = false
    }

    private struct Choice: Decodable { let message: Message }
    private struct Message: Decodable { let role: String; let content: String }
    private struct ChatResponse: Decodable { let choices: [Choice] }

    func complete(prompt: String, model: String) async throws -> String {
        print("🚀 Using xAI provider: \(model) [grokai]")
        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: model,
            messages: [
                ["role": "system", "content": "You are Grok, a helpful AI assistant."],
                ["role": "user", "content": prompt]
            ]
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "XAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // Backwards compatibility defaults
    func complete(prompt: String) async throws -> String {
        try await complete(prompt: prompt, model: "grok-beta")
    }
    func complete(messages: [[String: String]]) async throws -> String {
        try await complete(messages: messages, model: "grok-beta")
    }

    // New: multi-turn chat completion using full messages
    func complete(messages: [[String: String]], model: String) async throws -> String {
        print("🚀 Using xAI provider (multi-turn): \(model) [grokai]")
        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: model,
            messages: messages
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "XAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - ImageGenerationService
    func generateImage(prompt: String, size: String) async throws -> Data {
        throw ImageGenError.notSupported(provider: "xAI Grok")
    }
}
