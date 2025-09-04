import Foundation

struct XAIError: Error, Decodable { let message: String }

final class XAIService {
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

    func complete(prompt: String) async throws -> String {
        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: "grok-beta",
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
}
