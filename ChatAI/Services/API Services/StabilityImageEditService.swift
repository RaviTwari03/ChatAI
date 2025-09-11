//
//  StabilityImageEditService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 11/09/25.
//

import Foundation

final class StabilityImageEditService: ImageEditingService {
    static let shared = StabilityImageEditService()
    private init() {}

    private var apiKey: String {
        get throws { try APIManager.shared.getValidatedStabilityKey() }
    }

    // MARK: - Edit/Inpaint
    func edit(image: Data, mask: Data?, prompt: String, size: String = "1024x1024") async throws -> Data {
        guard let url = URL(string: "https://api.stability.ai/v2beta/stable-image/edit") else { throw ImageEditError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(try apiKey)", forHTTPHeaderField: "Authorization")
        // Stability returns binary image for Accept: image/png
        req.setValue("image/png", forHTTPHeaderField: "Accept")
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func addField(_ name: String, _ value: String) { body.append("--\(boundary)\r\n".data(using: .utf8)!); body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!); body.append("\(value)\r\n".data(using: .utf8)!) }
        func addFile(_ name: String, _ filename: String, _ mime: String, _ data: Data) { body.append("--\(boundary)\r\n".data(using: .utf8)!); body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!); body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!); body.append(data); body.append("\r\n".data(using: .utf8)!) }

        addFile("image", "image.png", "image/png", image)
        if let mask { addFile("mask", "mask.png", "image/png", mask) }
        if !prompt.isEmpty { addField("prompt", prompt) }
        // size is optional; Stability supports various resolutions depending on model
        addField("output_format", "png")

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ImageEditError.badResponse(status: http.statusCode, body: text)
        }
        return data
    }

    // MARK: - Background Removal
    func removeBackground(image: Data) async throws -> Data {
        guard let url = URL(string: "https://api.stability.ai/v2beta/stable-image/edit/remove-background") else { throw ImageEditError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(try apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("image/png", forHTTPHeaderField: "Accept")
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func addFile(_ name: String, _ filename: String, _ mime: String, _ data: Data) { body.append("--\(boundary)\r\n".data(using: .utf8)!); body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!); body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!); body.append(data); body.append("\r\n".data(using: .utf8)!) }
        addFile("image", "image.png", "image/png", image)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ImageEditError.badResponse(status: http.statusCode, body: text)
        }
        return data
    }

    // MARK: - Upscale
    func upscale(image: Data, scale: Int = 2) async throws -> Data {
        // Use Stability upscaler endpoint
        guard let url = URL(string: "https://api.stability.ai/v2beta/stable-image/upscale") else { throw ImageEditError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(try apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("image/png", forHTTPHeaderField: "Accept")
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func addField(_ name: String, _ value: String) { body.append("--\(boundary)\r\n".data(using: .utf8)!); body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!); body.append("\(value)\r\n".data(using: .utf8)!) }
        func addFile(_ name: String, _ filename: String, _ mime: String, _ data: Data) { body.append("--\(boundary)\r\n".data(using: .utf8)!); body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!); body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!); body.append(data); body.append("\r\n".data(using: .utf8)!) }

        addFile("image", "image.png", "image/png", image)
        addField("scale", String(scale))
        addField("output_format", "png")
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ImageEditError.badResponse(status: http.statusCode, body: text)
        }
        return data
    }
}
