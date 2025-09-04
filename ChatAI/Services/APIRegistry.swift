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
        APIProvider(id: "grokai", displayName: "GROK AI")
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
        default:
            return try await OpenAIService.shared.complete(prompt: prompt)
        }
    }
}
