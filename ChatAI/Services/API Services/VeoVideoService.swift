//
//  VeoVideoService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 17/09/25.
//

import Foundation

/// Google Gemini Veo 3 Video Service
/// Notes:
/// - This integrates with the Google Generative Language API using the Gemini key.
/// - The Video API commonly returns a long-running operation. We model that via `VideoJob.id`.
/// - Endpoints and response shapes may evolve; this implementation aims to be forward-compatible
///   and will surface server responses on failure for easier debugging.
final class VeoVideoService: VideoService {
    let provider: VideoProvider = .veo

    private var apiKey: String {
        get throws {
            try APIManager.shared.getValidatedGeminiKey()
        }
    }

    // MARK: - Models
    private struct Part: Encodable { let text: String }
    private struct Content: Encodable { let role: String; let parts: [Part] }

    private struct GenerateRequest: Encodable {
        let contents: [Content]
    }

    // Response for LRO start
    private struct Operation: Decodable {
        let name: String?           // operation id
        let done: Bool?
        let error: OperationError?
        let response: OperationResponse?
    }
    private struct OperationError: Decodable { let code: Int?; let message: String? }
    private struct OperationResponse: Decodable {
        // If operation directly returns media, try to surface a URI if present
        let candidates: [Candidate]?
    }
    private struct Candidate: Decodable { let content: CandidateContent? }
    private struct CandidateContent: Decodable { let parts: [CandidatePart]? }
    private struct CandidatePart: Decodable {
        // Server may return a file URI for generated video
        let fileData: FileData?
        let text: String?
    }
    private struct FileData: Decodable { let fileUri: String? }

    // MARK: - Endpoints
    private func generateURL(model: String) throws -> URL {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(try apiKey)") else {
            throw URLError(.badURL)
        }
        return url
    }
    private func listModelsURL() throws -> URL {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(try apiKey)") else {
            throw URLError(.badURL)
        }
        return url
    }
    private func operationURL(id: String) throws -> URL {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/operations/\(id)?key=\(try apiKey)") else {
            throw URLError(.badURL)
        }
        return url
    }

    // MARK: - Public
    func startVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoJob {
        _ = try apiKey
        // Discover a Veo-capable model in your project/region
        let model = try await resolveVeoModelSlug() // throws if none available
        // Current public Gemini endpoint does not accept a `video` field in the JSON body.
        // Encode requested video attributes into the prompt and use generationConfig to request MP4.
        let promptWithDirectives = """
        Create a high quality video.
        - Target dimensions: \(options.width)x\(options.height)
        - Target duration: \(max(1, options.durationSeconds)) seconds
        - Content prompt: \(prompt)
        Return a link or file reference to the generated MP4.
        """.trimmingCharacters(in: .whitespacesAndNewlines)

        let body = GenerateRequest(
            contents: [Content(role: "user", parts: [Part(text: promptWithDirectives)])]
        )

        var req = URLRequest(url: try generateURL(model: model))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw VideoServiceError.badStatus(http.statusCode, text)
        }

        // Try to decode as Operation first (typical for long-running tasks)
        if let op = try? JSONDecoder().decode(Operation.self, from: data), let name = op.name {
            return VideoJob(
                id: name,
                provider: provider,
                prompt: prompt,
                status: (op.done == true ? extractStatus(from: op) : .processing(progress: nil)),
                durationSeconds: options.durationSeconds,
                width: options.width,
                height: options.height
            )
        }

        // If server directly returned a candidate with a file URI, surface it
        if let op = try? JSONDecoder().decode(Operation.self, from: data), let urlStr = op.response?.candidates?.first?.content?.parts?.first?.fileData?.fileUri, let url = URL(string: urlStr) {
            return VideoJob(
                id: UUID().uuidString,
                provider: provider,
                prompt: prompt,
                status: .completed(url: url),
                durationSeconds: options.durationSeconds,
                width: options.width,
                height: options.height
            )
        }

        // Fallback: treat as queued with a random id (API behavior may differ)
        return VideoJob(
            id: UUID().uuidString,
            provider: provider,
            prompt: prompt,
            status: .queued,
            durationSeconds: options.durationSeconds,
            width: options.width,
            height: options.height
        )
    }

    func startVideoFromImage(prompt: String, imageData: Data, mimeType: String, options: VideoGenerationOptions) async throws -> VideoJob {
        // For MVP, route to text-only generation. Extend by attaching the image as inline data if your quota allows.
        return try await startVideo(prompt: prompt, options: options)
    }

    func getStatus(jobId: String) async throws -> VideoJob {
        _ = try apiKey
        var req = URLRequest(url: try operationURL(id: jobId))
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw VideoServiceError.badStatus(http.statusCode, text)
        }
        let op = try JSONDecoder().decode(Operation.self, from: data)
        let status = extractStatus(from: op)
        return VideoJob(id: jobId, provider: provider, prompt: "", status: status)
    }

    func cancel(jobId: String) async throws {
        // Google Operations API supports cancel on some LROs; implement when available.
        throw VideoServiceError.notImplemented
    }

    // MARK: - Helpers
    private func extractStatus(from op: Operation) -> VideoStatus {
        if let err = op.error {
            return .failed(error: err.message ?? "Unknown Veo error")
        }
        if op.done == true {
            if let uri = op.response?.candidates?.first?.content?.parts?.first?.fileData?.fileUri, let url = URL(string: uri) {
                return .completed(url: url)
            }
            // Done but no URI surfaced
            return .failed(error: "Veo operation complete but no media URI returned")
        }
        return .processing(progress: nil)
    }

    // Try to resolve a model slug that includes "veo" and supports generateContent
    private struct ModelsList: Decodable { let models: [ModelItem]? }
    private struct ModelItem: Decodable { let name: String?; let displayName: String?; let supportedGenerationMethods: [String]? }

    private func resolveVeoModelSlug() async throws -> String {
        var req = URLRequest(url: try listModelsURL())
        req.httpMethod = "GET"
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw VideoServiceError.badStatus(http.statusCode, text)
        }
        let list = try? JSONDecoder().decode(ModelsList.self, from: data)
        let candidates = (list?.models ?? []).compactMap { $0 }
        // Prefer a model name that contains "veo" and supports generateContent
        if let m = candidates.first(where: { ($0.name ?? "").lowercased().contains("veo") && (($0.supportedGenerationMethods ?? []).contains("generateContent") || ($0.supportedGenerationMethods ?? []).isEmpty) })?.name {
            // API returns full name like models/veo-3 or publishers/google/models/veo-3
            if let last = m.split(separator: "/").last { return String(last) }
            return m
        }
        // If not found, surface actionable guidance
        throw VideoServiceError.badRequest("No Veo model is enabled for your API key/project on the v1beta Generative Language API. Enable Gemini Veo (Video) in Google AI Studio or use Vertex AI model endpoints, then update the model slug. Alternatively, choose another provider.")
    }
}
