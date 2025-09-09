//
//  DeepSeekService.swift
//  ChatAI
//
//  Created by Cascade on 09/09/25.
//

import Foundation

struct DeepSeekError: Error, Decodable { let message: String }

final class DeepSeekService {
    static let shared = DeepSeekService()
    private init() {}

    // Use secure APIManager for API key access
    private var apiKey: String {
        do {
            return try APIManager.shared.getValidatedDeepSeekKey()
        } catch {
            fatalError("DeepSeek API key error: \(error.localizedDescription). Please check your Secrets.xcconfig file.")
        }
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [[String: String]]
        let stream: Bool? = nil
    }

    private struct Choice: Decodable { let message: Message }
    private struct Message: Decodable { let role: String; let content: String }
    private struct ChatResponse: Decodable { let choices: [Choice] }

    /// Single-turn completion from a prompt string
    func complete(prompt: String) async throws -> String {
        print("🚀 Using DeepSeek provider: deepseek-chat [deepseek]")
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: "deepseek-chat",
            messages: [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ]
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DeepSeek", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Multi-turn completion using an existing list of messages
    func complete(messages: [[String: String]]) async throws -> String {
        print("🚀 Using DeepSeek provider (multi-turn): deepseek-chat [deepseek]")
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: "deepseek-chat",
            messages: messages
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DeepSeek", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
