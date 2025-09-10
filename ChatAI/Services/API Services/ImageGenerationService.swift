//
//  ImageGenerationService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 10/09/25.
//

import Foundation

public protocol ImageGenerationService {
    /// Generate an image from a text prompt.
    /// - Parameters:
    ///   - prompt: Text description of the image to generate
    ///   - size: Image size such as "512x512" or "1024x1024"
    /// - Returns: Raw image data (PNG/JPEG)
    func generateImage(prompt: String, size: String) async throws -> Data
}

public enum ImageGenError: LocalizedError {
    case notSupported(provider: String)

    public var errorDescription: String? {
        switch self {
        case .notSupported(let provider):
            return "Image generation is not supported by provider: \(provider)"
        }
    }
}
