//
//  GeminiService.swift
//  ChatAI
//
//  Created by Cascade on 08/09/25.
//

import Foundation

struct GeminiError: Error, Decodable { let message: String? }

final class GeminiService: ImageGenerationService {
    static let shared = GeminiService()
    private init() {}

    // Use secure APIManager for API key access
    private var apiKey: String {
        do {
            return try APIManager.shared.getValidatedGeminiKey()
        } catch {
            fatalError("Gemini API key error: \(error.localizedDescription). Please check your Secrets.xcconfig and target Info properties (GEMINI_API_KEY = $(GEMINI_API_KEY)).")
        }
    }

    // MARK: - Request/Response Models
    private struct Part: Encodable { let text: String }
    private struct Content: Encodable { let role: String; let parts: [Part] }
    private struct GenerateRequest: Encodable { let contents: [Content] }

    private struct CandidatePart: Decodable { let text: String? }
    private struct CandidateContent: Decodable { let parts: [CandidatePart] }
    private struct GenerateResponse: Decodable { let candidates: [Candidate] }
    private struct Candidate: Decodable { let content: CandidateContent }

    // MARK: - Public API
    func complete(prompt: String, model: String) async throws -> String {
        print("🚀 Using Google provider: \(model) [gemini]")
        let user = Content(role: "user", parts: [Part(text: prompt)])
        let body = GenerateRequest(contents: [user])
        return try await send(body: body, model: model)
    }

    func complete(messages: [[String: String]], model: String) async throws -> String {
        print("🚀 Using Google provider (multi-turn): \(model) [gemini]")
        // Map generic messages to Gemini contents. If role missing, default to user.
        let contents: [Content] = messages.map { m in
            let role = (m["role"] ?? "user").lowercased() == "assistant" ? "model" : "user"
            let text = m["content"] ?? ""
            return Content(role: role, parts: [Part(text: text)])
        }
        let body = GenerateRequest(contents: contents)
        return try await send(body: body, model: model)
    }

    // MARK: - Networking
    private func send(body: GenerateRequest, model: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Gemini", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        let text = decoded.candidates.first?.content.parts.compactMap { $0.text }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text ?? ""
    }

    // Backwards compatibility defaults
    func complete(prompt: String) async throws -> String {
        try await complete(prompt: prompt, model: "gemini-1.5-flash")
    }
    func complete(messages: [[String: String]]) async throws -> String {
        try await complete(messages: messages, model: "gemini-1.5-flash")
    }

    // MARK: - ImageGenerationService
    func generateImage(prompt: String, size: String) async throws -> Data {
        // Note: Gemini image generation (Imagen) typically requires Google Cloud setup beyond simple API key usage.
        throw ImageGenError.notSupported(provider: "Google Gemini")
    }
}
