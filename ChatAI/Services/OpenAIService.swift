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

    // Read from Info.plist key OPENAI_API_KEY, fallback to provided runtime key while developing
    private var apiKey: String {
        if let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        // TEMP: fallback (replace/remove for production)
        return "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"
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [[String: String]]
    }

    private struct Choice: Decodable { let message: Message }
    private struct Message: Decodable { let role: String; let content: String }
    private struct ChatResponse: Decodable { let choices: [Choice] }

    func complete(prompt: String) async throws -> String {
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
