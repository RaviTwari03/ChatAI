//
//  APIRegistry.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import Foundation

struct APIProvider: Identifiable, Equatable {
    let id: String            // unique selection id, e.g. "openai:gpt-4.1-mini"
    let displayName: String   // shown in UI
}

/// Central place to declare which API providers are available and manage runtime switching.
/// Update this file when you add/remove a provider implementation.
final class APIRegistry {
    static let shared = APIRegistry()

    /// Available providers exposed to the UI as specific model variants (to mirror UX in screenshots)
    /// Note: IDs use the format "family:model" when applicable, so routing can detect provider family and model.
    let providers: [APIProvider] = [
        // OpenAI
        APIProvider(id: "openai:chatgpt-5-mini", displayName: "ChatGPT 5 mini"),
        APIProvider(id: "openai:gpt-4.1", displayName: "ChatGPT 4.1"),
        APIProvider(id: "openai:gpt-4.1-mini", displayName: "ChatGPT 4.1 mini"),
        APIProvider(id: "openai:gpt-o4-mini-high", displayName: "GPT o4-mini (high)"),
        APIProvider(id: "openai:gpt-4o-mini", displayName: "ChatGPT mini"),

        // xAI Grok
        APIProvider(id: "grokai:grok-4", displayName: "Grok 4"),

        // Google Gemini
        APIProvider(id: "gemini:gemini-2.5-pro", displayName: "Gemini 2.5 Pro"),
        APIProvider(id: "gemini:gemini-2.0-flash", displayName: "Gemini 2.0 Flash"),
        APIProvider(id: "gemini:gemini-1.5-flash", displayName: "Gemini 1.5 Flash"),

        // Anthropic Claude
        APIProvider(id: "claude:claude-3.7-sonnet", displayName: "Claude 3.7 Sonnet"),
        APIProvider(id: "claude:claude-3.5-sonnet", displayName: "Claude 3.5 Sonnet"),

        // DeepSeek
        APIProvider(id: "deepseek:deepseek-r1", displayName: "DeepSeek-R1"),

        // Stability (image edits)
        APIProvider(id: "stability:sd", displayName: "Stability")
    ]

    private let defaults = UserDefaults.standard
    private let selectionKey = "api.provider.selection"

    private init() {
        // Ensure a default provider is set once
        if defaults.string(forKey: selectionKey) == nil {
            defaults.set("openai:gpt-4o-mini", forKey: selectionKey)
            print("🟢 Default API provider set to: ChatGPT mini [openai:gpt-4o-mini]")
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
            currentProviderId = "openai:gpt-4o-mini"
            return
        }
        currentProviderId = id
    }

    // MARK: - Resolve Provider Family and Model
    private func familyAndModel(from id: String) -> (family: String, model: String?) {
        if let range = id.range(of: ":") {
            let fam = String(id[id.startIndex..<range.lowerBound])
            let model = String(id[range.upperBound...])
            return (fam, model)
        }
        return (id, nil)
    }

    /// Convenience router for sending a chat request using the active provider.
    /// You can call this from your view model / UI instead of referencing a concrete service.
    @discardableResult
    func complete(prompt: String) async throws -> String {
        let selected = activeProvider()
        let (family, model) = familyAndModel(from: selected.id)
        print("🔁 Using provider: \(selected.displayName) [\(selected.id)]")
        switch family {
        case "grokai":
            return try await XAIService.shared.complete(prompt: prompt, model: model ?? "grok-beta")
        case "gemini":
            return try await GeminiService.shared.complete(prompt: prompt, model: model ?? "gemini-1.5-flash")
        case "deepseek":
            return try await DeepSeekService.shared.complete(prompt: prompt)
        case "claude":
            return try await ClaudeService.shared.complete(prompt: prompt)
        default:
            return try await OpenAIService.shared.complete(prompt: prompt, model: model ?? "gpt-4o-mini")
        }
    }

    /// Multi-turn completion router using a full messages array
    /// messages format: [["role": "system|user|assistant", "content": "..."]]
    @discardableResult
    func complete(messages: [[String: String]]) async throws -> String {
        let selected = activeProvider()
        let (family, model) = familyAndModel(from: selected.id)
        print("🔁 Using provider (multi-turn): \(selected.displayName) [\(selected.id)]")
        switch family {
        case "grokai":
            return try await XAIService.shared.complete(messages: messages, model: model ?? "grok-beta")
        case "gemini":
            return try await GeminiService.shared.complete(messages: messages, model: model ?? "gemini-1.5-flash")
        case "deepseek":
            return try await DeepSeekService.shared.complete(messages: messages)
        case "claude":
            return try await ClaudeService.shared.complete(messages: messages)
        default:
            return try await OpenAIService.shared.complete(messages: messages, model: model ?? "gpt-4o-mini")
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
        switch familyAndModel(from: selected.id).family {
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
        switch familyAndModel(from: selected.id).family {
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
        switch familyAndModel(from: selected.id).family {
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
        switch familyAndModel(from: selected.id).family {
        case "stability":
            return try await StabilityImageEditService.shared.upscale(image: image, scale: scale)
        default:
            return try await OpenAIImageEditService.shared.upscale(image: image, scale: scale)
        }
    }
}
