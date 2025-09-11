//
//  OpenAIImageEditService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 11/09/25.
//

import Foundation

final class OpenAIImageEditService: ImageEditingService {
    static let shared = OpenAIImageEditService()
    private init() {}

    private var apiKey: String {
        get throws {
            try APIManager.shared.getValidatedOpenAIKey()
        }
    }

    private struct EditResponse: Decodable {
        struct Item: Decodable { let b64_json: String?; let url: String? }
        let data: [Item]
    }

    func edit(image: Data, mask: Data?, prompt: String, size: String = "1024x1024") async throws -> Data {
        guard let url = URL(string: "https://api.openai.com/v1/images/edits") else { throw ImageEditError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(try apiKey)", forHTTPHeaderField: "Authorization")
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func addField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        func addFile(_ name: String, _ filename: String, _ mime: String, _ data: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        addFile("image", "image.png", "image/png", image)
        if let mask { addFile("mask", "mask.png", "image/png", mask) }
        addField("prompt", prompt)
        addField("size", size)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ImageEditError.badResponse(status: http.statusCode, body: text)
        }
        let decoded = try JSONDecoder().decode(EditResponse.self, from: data)
        guard let first = decoded.data.first else { throw ImageEditError.parse }
        if let b64 = first.b64_json, let out = Data(base64Encoded: b64) { return out }
        if let urlStr = first.url, let u = URL(string: urlStr) {
            let (img, resp2) = try await URLSession.shared.data(from: u)
            if let http = resp2 as? HTTPURLResponse, http.statusCode >= 300 { throw ImageEditError.badResponse(status: http.statusCode, body: "download failed") }
            return img
        }
        throw ImageEditError.parse
    }

    func removeBackground(image: Data) async throws -> Data {
        // OpenAI has no dedicated background removal. We'll attempt a full-image edit with instruction.
        // Without a mask, results may not be transparent. Communicate limitation by throwing notSupported.
        throw ImageEditError.notSupported(provider: "OpenAI", operation: "removeBackground")
    }

    func upscale(image: Data, scale: Int) async throws -> Data {
        // OpenAI does not provide an upscaler endpoint at this time.
        throw ImageEditError.notSupported(provider: "OpenAI", operation: "upscale")
    }
}
