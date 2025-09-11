//
//  ImageEditingService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 11/09/25.
//

import Foundation

public protocol ImageEditingService {
    /// Inpaint or edit an image using an optional mask and a text prompt.
    /// - Parameters:
    ///   - image: Original image data (PNG/JPEG). For best results use PNG.
    ///   - mask: Optional mask PNG. Transparent areas indicate regions to edit.
    ///   - prompt: Instruction for the edit (e.g., "remove the sun").
    ///   - size: Result size (e.g., "1024x1024"). Provider may ignore.
    /// - Returns: Edited image data.
    func edit(image: Data, mask: Data?, prompt: String, size: String) async throws -> Data

    /// Remove the background from an image.
    func removeBackground(image: Data) async throws -> Data

    /// Upscale or enhance an image by an integer scale (e.g., 2, 4).
    func upscale(image: Data, scale: Int) async throws -> Data
}

public enum ImageEditError: LocalizedError {
    case notSupported(provider: String, operation: String)
    case badURL
    case badResponse(status: Int, body: String)
    case parse
    case notConfigured(message: String)

    public var errorDescription: String? {
        switch self {
        case let .notSupported(provider, op):
            return "Operation \(op) is not supported by provider: \(provider)"
        case .badURL:
            return "Malformed URL for image editing request"
        case let .badResponse(status, body):
            return "Image editing request failed (status: \(status)) - \(body)"
        case .parse:
            return "Failed to parse image editing response"
        case .notConfigured(let message):
            return message
        }
    }
}
