//
//  APIRegistry.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import Foundation

struct APIProvider: Identifiable, Equatable {
    let id: String
    let displayName: String
}

/// Central place to declare which API providers are available and manage runtime switching.
/// Update this file when you add/remove a provider implementation.
final class APIRegistry {
    static let shared = APIRegistry()

    /// Available providers exposed to the UI
    let providers: [APIProvider] = [
        APIProvider(id: "openai", displayName: "ChatGPT mini"),
        APIProvider(id: "grokai", displayName: "GROK AI"),
        APIProvider(id: "gemini", displayName: "Gemini"),
        APIProvider(id: "deepseek", displayName: "DeepSeek"),
        APIProvider(id: "claude", displayName: "Claude"),
        APIProvider(id: "stability", displayName: "Stability")
    ]

    private let defaults = UserDefaults.standard
    private let selectionKey = "api.provider.selection"

    private init() {
        // Ensure a default provider is set once
        if defaults.string(forKey: selectionKey) == nil {
            defaults.set("openai", forKey: selectionKey)
            print("🟢 Default API provider set to: ChatGPT mini [openai]")
        }
    }

    /// The currently selected provider id (persisted)
    var currentProviderId: String {
        get { defaults.string(forKey: selectionKey) ?? "openai" }
        set {
            defaults.set(newValue, forKey: selectionKey)
            let name = activeProvider().displayName
            print("🟢 Switched API provider to: \(name) [\(newValue)]")
        }
    }

    /// Returns the full provider object for the current selection
    func activeProvider() -> APIProvider {
        providers.first { $0.id == currentProviderId } ?? providers[0]
    }

    /// Call this from the UI when user selects a provider from the menu
    func setCurrentProvider(id: String) {
        guard providers.contains(where: { $0.id == id }) else {
            print("⚠️ Unknown provider id: \(id). Falling back to OpenAI.")
            currentProviderId = "openai"
            return
        }
        currentProviderId = id
    }

    /// Convenience router for sending a chat request using the active provider.
    /// You can call this from your view model / UI instead of referencing a concrete service.
    @discardableResult
    func complete(prompt: String) async throws -> String {
        let selected = activeProvider()
        print("🔁 Using provider: \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "grokai":
            return try await XAIService.shared.complete(prompt: prompt)
        case "gemini":
            return try await GeminiService.shared.complete(prompt: prompt)
        case "deepseek":
            return try await DeepSeekService.shared.complete(prompt: prompt)
        case "claude":
            return try await ClaudeService.shared.complete(prompt: prompt)
        default:
            return try await OpenAIService.shared.complete(prompt: prompt)
        }
    }

    /// Multi-turn completion router using a full messages array
    /// messages format: [["role": "system|user|assistant", "content": "..."]]
    @discardableResult
    func complete(messages: [[String: String]]) async throws -> String {
        let selected = activeProvider()
        print("🔁 Using provider (multi-turn): \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "grokai":
            return try await XAIService.shared.complete(messages: messages)
        case "gemini":
            return try await GeminiService.shared.complete(messages: messages)
        case "deepseek":
            return try await DeepSeekService.shared.complete(messages: messages)
        case "claude":
            return try await ClaudeService.shared.complete(messages: messages)
        default:
            return try await OpenAIService.shared.complete(messages: messages)
        }
    }

    // MARK: - Image Generation Router
    /// Generate an image using the active provider. Currently supported: OpenAI
    /// - Parameters:
    ///   - prompt: Image prompt text
    ///   - size: Size string like "512x512" or "1024x1024"
    /// - Returns: Raw image data (PNG/JPEG)
    func generateImage(prompt: String, size: String = "1024x1024") async throws -> Data {
        let selected = activeProvider()
        print("🖼️ Using provider for image gen: \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "grokai":
            // Not yet implemented for xAI
            throw NSError(domain: "APIRegistry.Image", code: -100, userInfo: [NSLocalizedDescriptionKey: "Image generation not supported for GROK AI yet. Switch to OpenAI in settings."])
        default:
            return try await OpenAIService.shared.generateImage(prompt: prompt, size: size)
        }
    }

    // MARK: - Vision Analysis Router (Image + Question)
    func analyzeImage(question: String, imageData: Data, mimeType: String = "image/png") async throws -> String {
        let selected = activeProvider()
        print("👀 Using provider for vision: \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "grokai":
            throw NSError(domain: "APIRegistry.Vision", code: -200, userInfo: [NSLocalizedDescriptionKey: "Vision Q&A not supported for GROK AI yet. Switch to OpenAI in settings."])
        default:
            return try await OpenAIService.shared.analyzeImage(question: question, imageData: imageData, mimeType: mimeType)
        }
    }

    // MARK: - Image Editing Routers
    func editImage(image: Data, mask: Data?, prompt: String, size: String = "1024x1024") async throws -> Data {
        let selected = activeProvider()
        print("✏️ Image edit via provider: \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "stability":
            return try await StabilityImageEditService.shared.edit(image: image, mask: mask, prompt: prompt, size: size)
        default:
            return try await OpenAIImageEditService.shared.edit(image: image, mask: mask, prompt: prompt, size: size)
        }
    }

    func removeBackground(image: Data) async throws -> Data {
        let selected = activeProvider()
        print("🧼 Background removal via: \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "stability":
            return try await StabilityImageEditService.shared.removeBackground(image: image)
        default:
            // OpenAI does not have a dedicated background removal; simulate with full-image edit and prompt
            return try await OpenAIImageEditService.shared.removeBackground(image: image)
        }
    }

    func upscale(image: Data, scale: Int = 2) async throws -> Data {
        let selected = activeProvider()
        print("🔍 Upscale via: \(selected.displayName) [\(selected.id)]")
        switch selected.id {
        case "stability":
            return try await StabilityImageEditService.shared.upscale(image: image, scale: scale)
        default:
            return try await OpenAIImageEditService.shared.upscale(image: image, scale: scale)
        }
    }
}
