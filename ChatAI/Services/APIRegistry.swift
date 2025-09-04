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

/// Central place to declare which API providers are available in the app.
/// Update this list when you add/remove a provider implementation.
struct APIRegistry {
    static let shared = APIRegistry()

    // Currently only OpenAI is implemented by `OpenAIService`
    let providers: [APIProvider] = [
        APIProvider(id: "openai", displayName: "ChatGPT mini"),
        APIProvider(id: "grokai", displayName: "GROK AI")
    ]
}
