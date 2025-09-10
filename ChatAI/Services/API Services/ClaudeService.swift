//
//  ClaudeService.swift
//  ChatAI
//
//  Created by Cascade on 09/09/25.
//

import Foundation

/// Minimal Anthropic Claude client for text chat.
/// Requires CLAUDE_API_KEY to be provided via Info.plist (Custom iOS Target Properties -> $(CLAUDE_API_KEY))
/// and Secrets.xcconfig.
final class ClaudeService: ImageGenerationService {
    static let shared = ClaudeService()
    private init() {}

private struct AnthropicErrorResponse: Decodable {
    struct Inner: Decodable { let type: String?; let message: String? }
    let type: String?
    let error: Inner
    let request_id: String?
}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    // Prefer a stable model id to avoid 404 alias issues on some accounts
    private var model: String {
        // Allow override via Info.plist key CLAUDE_MODEL if provided
        if let override = Bundle.main.infoDictionary?["CLAUDE_MODEL"] as? String, !override.isEmpty { return override }
        return "claude-3-5-sonnet-20240620"
    }

    enum ClaudeError: LocalizedError {
        case missingKey
        case invalidResponse
        case badStatus(Int, String?, String?) // status, message, request_id
        case network(Error)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .missingKey: return "CLAUDE_API_KEY is missing or invalid."
            case .invalidResponse: return "Invalid response from Claude API."
            case .badStatus(let code, let body, let reqId):
                var msg = "Claude API returned status: \(code)"
                if let body, !body.isEmpty { msg += " — \(body)" }
                if let reqId, !reqId.isEmpty { msg += " (request_id: \(reqId))" }
                return msg
            case .network(let e): return e.localizedDescription
            case .decoding(let e): return "Decoding error: \(e.localizedDescription)"
            }
        }
    }

    // MARK: - Public API

    @discardableResult
    func complete(prompt: String) async throws -> String {
        let messages: [[String: String]] = [["role": "user", "content": prompt]]
        return try await complete(messages: messages)
    }

    /// messages format: [["role": "system|user|assistant", "content": String]]
    @discardableResult
    func complete(messages: [[String: String]]) async throws -> String {
        let key = try APIManager.shared.getValidatedClaudeKey()
        let body = try buildBody(messages: messages)

        // Primary model then fallbacks for accounts without access to specific ids
        let candidates: [String] = {
            var arr = [self.model]
            // Try a couple of widely available options if first fails
            let fallbacks = [
                "claude-3-5-sonnet-latest",
                "claude-3-5-haiku-20241022",
                "claude-3-haiku-20240307"
            ]
            for m in fallbacks where !arr.contains(m) { arr.append(m) }
            return arr
        }()

        var lastError: Error? = nil
        for candidate in candidates {
            do {
                return try await sendRequest(apiKey: key, model: candidate, body: body)
            } catch let ClaudeError.badStatus(code, bodyMsg, _) {
                // If model not found (404), try next candidate
                if code == 404, let bodyMsg, bodyMsg.contains("model") {
                    lastError = ClaudeError.badStatus(code, bodyMsg, nil)
                    continue
                }
                // Other status: bubble up immediately
                throw ClaudeError.badStatus(code, bodyMsg, nil)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? ClaudeError.invalidResponse
    }

    private func sendRequest(apiKey: String, model: String, body: Data) async throws -> String {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try rewriteBodyWithModel(originalBody: body, model: model)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ClaudeError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8)
            let parsed = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data)
            let combined = parsed?.error.message ?? raw
            throw ClaudeError.badStatus(http.statusCode, combined, parsed?.request_id)
        }
        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return decoded.combinedText()
    }

    // MARK: - Helpers

    private func buildBody(messages: [[String: String]]) throws -> Data {
        // Anthropic's Messages API doesn't support a separate system field; include system content as first user message with role "system"
        var anthroMessages: [AnthropicMessage] = []
        for m in messages {
            let role = m["role"] ?? "user"
            let content = m["content"] ?? ""
            if role == "system" {
                // Anthropic supports a top-level system string as of newer versions;
                // but for broad compatibility, prepend as a user message tagged [system]
                anthroMessages.append(AnthropicMessage(role: "user", content: [.text("[system] \(content)")]))
            } else if role == "user" {
                anthroMessages.append(AnthropicMessage(role: "user", content: [.text(content)]))
            } else {
                // assistant
                anthroMessages.append(AnthropicMessage(role: "assistant", content: [.text(content)]))
            }
        }
        let body = ClaudeRequest(model: model, max_tokens: 1024, messages: anthroMessages)
        return try JSONEncoder().encode(body)
    }

    private func rewriteBodyWithModel(originalBody: Data, model: String) throws -> Data {
        var payload = try JSONDecoder().decode(ClaudeRequest.self, from: originalBody)
        payload = ClaudeRequest(model: model, max_tokens: payload.max_tokens, messages: payload.messages)
        return try JSONEncoder().encode(payload)
    }
    
    // MARK: - ImageGenerationService
    func generateImage(prompt: String, size: String) async throws -> Data {
        throw ImageGenError.notSupported(provider: "Anthropic Claude")
    }
}

// MARK: - DTOs

private struct ClaudeRequest: Codable {
    var model: String
    var max_tokens: Int
    var messages: [AnthropicMessage]
}

private struct AnthropicMessage: Codable {
    let role: String // "user" | "assistant"
    let content: [AnthropicContent]
}

private enum AnthropicContent: Codable {
    case text(String)

    enum CodingKeys: String, CodingKey { case type, text }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let s):
            try c.encode("text", forKey: .type)
            try c.encode(s, forKey: .text)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported content type: \(type)")
        }
    }
}

private struct ClaudeResponse: Decodable {
    struct Item: Decodable {
        let type: String?
        let text: String?
    }
    let content: [Item]

    func combinedText() -> String {
        content.compactMap { $0.text }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
