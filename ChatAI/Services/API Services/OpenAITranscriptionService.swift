//
//  OpenAITranscriptionService.swift
//  ChatAI
//
//  Provides Whisper-based audio transcription via OpenAI's API.
//

import Foundation

final class OpenAITranscriptionService {
    static let shared = OpenAITranscriptionService()
    private init() {}

    private var apiKey: String {
        do {
            return try APIManager.shared.getValidatedOpenAIKey()
        } catch {
            fatalError("OpenAI API key error: \(error.localizedDescription). Please check your Secrets.xcconfig file and Info properties.")
        }
    }

    /// Transcribe an audio file with OpenAI Whisper API.
    /// - Parameters:
    ///   - fileURL: local URL of audio file (mp3, m4a, wav, aiff)
    ///   - model: Whisper model id (default: whisper-1)
    func transcribe(fileURL: URL, model: String = "whisper-1") async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-" + UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let filename = fileURL.lastPathComponent
        let mimeType: String
        switch fileURL.pathExtension.lowercased() {
        case "wav": mimeType = "audio/wav"
        case "aiff", "aif": mimeType = "audio/aiff"
        case "m4a": mimeType = "audio/m4a"
        case "mp3": mimeType = "audio/mpeg"
        default: mimeType = "application/octet-stream"
        }

        var body = Data()
        func append(_ str: String) { body.append(str.data(using: .utf8)!) }

        // model field
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append("\(model)\r\n")

        // file field
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        let fileData = try Data(contentsOf: fileURL)
        body.append(fileData)
        append("\r\n")

        // close
        append("--\(boundary)--\r\n")

        request.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: request)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI.Whisper", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        struct WhisperResponse: Decodable { let text: String }
        let decoded = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return decoded.text
    }
}
