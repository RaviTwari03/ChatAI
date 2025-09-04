//
//  OpenAIService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import Foundation

struct OpenAIError: Error, Decodable { let message: String }

final class OpenAIService {
    static let shared = OpenAIService()
    private init() {}

    // Use secure APIManager for API key access
    private var apiKey: String {
        do {
            return try APIManager.shared.getValidatedOpenAIKey()
        } catch {
            fatalError("OpenAI API key error: \(error.localizedDescription). Please check your Secrets.xcconfig file.")
        }
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [[String: String]]
    }

    private struct Choice: Decodable { let message: Message }
    private struct Message: Decodable { let role: String; let content: String }
    private struct ChatResponse: Decodable { let choices: [Choice] }

    func complete(prompt: String) async throws -> String {
        print("🚀 Using OpenAI provider: ChatGPT mini [openai]")
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ]
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
