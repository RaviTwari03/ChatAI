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
        let stream: Bool? = nil
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

    // New: multi-turn chat completion using full message list
    func complete(messages: [[String: String]]) async throws -> String {
        print("🚀 Using OpenAI provider (multi-turn): ChatGPT mini [openai]")
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: "gpt-4o-mini",
            messages: messages
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

    // MARK: - Image Generation
    private struct ImageGenRequest: Encodable {
        let prompt: String
        let model: String
        let size: String
        // NOTE: Some accounts may not accept response_format. We'll omit it and handle URL or base64 in response.
    }

    private struct ImageGenResponse: Decodable {
        struct Item: Decodable {
            let b64_json: String?
            let url: String?
        }
        let data: [Item]
    }

    /// Generate an image from a text prompt using OpenAI's image model.
    /// - Parameters:
    ///   - prompt: Text description of the image to generate
    ///   - size: Image size, e.g. "512x512", "1024x1024"
    /// - Returns: PNG/JPEG image data decoded from base64
    func generateImage(prompt: String, size: String = "1024x1024") async throws -> Data {
        print("🖼️ Generating image with OpenAI: gpt-image-1 size=\(size)")
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ImageGenRequest(prompt: prompt, model: "gpt-image-1", size: size)
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI.Image", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let decoded = try JSONDecoder().decode(ImageGenResponse.self, from: data)
        guard let first = decoded.data.first else {
            throw NSError(domain: "OpenAI.Image", code: -1, userInfo: [NSLocalizedDescriptionKey: "No image returned"])
        }
        if let b64 = first.b64_json, let imgData = Data(base64Encoded: b64) {
            return imgData
        }
        if let urlStr = first.url, let url = URL(string: urlStr) {
            let (imgData, urlResp) = try await URLSession.shared.data(from: url)
            if let http = urlResp as? HTTPURLResponse, http.statusCode >= 300 {
                throw NSError(domain: "OpenAI.Image", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to download image from URL"])
            }
            return imgData
        }
        throw NSError(domain: "OpenAI.Image", code: -2, userInfo: [NSLocalizedDescriptionKey: "No usable image data in response"])
    }
}
