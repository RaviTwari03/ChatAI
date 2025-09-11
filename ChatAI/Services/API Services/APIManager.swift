//
//  APIManager.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 04/09/25.
//

import Foundation

/// Secure API Manager for handling API keys and configuration
class APIManager {
    
    // MARK: - Singleton
    static let shared = APIManager()
    
    // MARK: - Properties
    private let bundle: Bundle
    
    // MARK: - Initialization
    private init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }
    
    // MARK: - API Key Access
    
    /// Get OpenAI API Key from secure configuration
    var openAIAPIKey: String? {
        return getAPIKey(for: "OPENAI_API_KEY")
    }
    
    /// Get xAI (Grok) API Key from secure configuration
    var xaiAPIKey: String? {
        return getAPIKey(for: "XAI_API_KEY")
    }
    
    /// Get Google Gemini API Key from secure configuration
    var geminiAPIKey: String? {
        return getAPIKey(for: "GEMINI_API_KEY")
    }

    /// Get Pika API Key from secure configuration
    var pikaAPIKey: String? {
        return getAPIKey(for: "PIKA_API_KEY")
    }

    /// Get DeepSeek API Key from secure configuration
    var deepseekAPIKey: String? {
        return getAPIKey(for: "DEEPSEEK_API_KEY")
    }
    
    /// Get Claude (Anthropic) API Key from secure configuration
    var claudeAPIKey: String? {
        return getAPIKey(for: "CLAUDE_API_KEY")
    }

    /// Get Stability API Key from secure configuration
    var stabilityAPIKey: String? {
        return getAPIKey(for: "STABILITY_API_KEY")
    }

    /// Get Cloudinary credentials from secure configuration
    var cloudinaryCloudName: String? { bundle.infoDictionary?["CLOUDINARY_CLOUD_NAME"] as? String }
    var cloudinaryAPIKey: String? { bundle.infoDictionary?["CLOUDINARY_API_KEY"] as? String }
    var cloudinaryAPISecret: String? { bundle.infoDictionary?["CLOUDINARY_API_SECRET"] as? String }
    
    // MARK: - Private Methods
    
    /// Securely retrieve API key from bundle configuration
    /// - Parameter key: The key name to retrieve
    /// - Returns: The API key string if found, nil otherwise
    private func getAPIKey(for key: String) -> String? {
        guard let apiKey = bundle.infoDictionary?[key] as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix("$("),  // Check it's not a placeholder
              !apiKey.contains("your-") // Check it's not a template value
        else {
            print("⚠️ Warning: API key '\(key)' not found or is a placeholder")
            return nil
        }
        
        return apiKey
    }
    
    // MARK: - Validation Methods
    
    /// Validate that all required API keys are properly configured
    /// - Returns: True if all keys are valid, false otherwise
    func validateAPIKeys() -> Bool {
        let openAIValid = openAIAPIKey != nil
        let xaiValid = xaiAPIKey != nil
        let geminiValid = geminiAPIKey != nil
        let pikaValid = pikaAPIKey != nil
        let deepseekValid = deepseekAPIKey != nil
        let claudeValid = claudeAPIKey != nil
        let stabilityValid = stabilityAPIKey != nil
        
        if !openAIValid {
            print("❌ OpenAI API key is missing or invalid")
        }
        
        if !xaiValid {
            print("❌ xAI API key is missing or invalid")
        }
        
        if !geminiValid {
            print("❌ Gemini API key is missing or invalid")
        }
        
        if !pikaValid {
            print("❌ Pika API key is missing or invalid")
        }
        
        if !deepseekValid {
            print("❌ DeepSeek API key is missing or invalid")
        }
        
        if !claudeValid {
            print("❌ Claude API key is missing or invalid")
        }
        
        if !stabilityValid {
            print("❌ Stability API key is missing or invalid (needed for image edit/background removal)")
        }
        
        return openAIValid && xaiValid && geminiValid && pikaValid && deepseekValid && claudeValid && stabilityValid
    }
    
    /// Get configuration status for debugging
    /// - Returns: Dictionary with configuration status
    func getConfigurationStatus() -> [String: Any] {
        return [
            "openAI_configured": openAIAPIKey != nil,
            "xai_configured": xaiAPIKey != nil,
            "pika_configured": pikaAPIKey != nil,
            "deepseek_configured": deepseekAPIKey != nil,
            "claude_configured": claudeAPIKey != nil,
            "stability_configured": stabilityAPIKey != nil,
            "bundle_identifier": bundle.bundleIdentifier ?? "unknown",
            "info_plist_keys": bundle.infoDictionary?.keys.sorted() ?? []
        ]
    }
}

// MARK: - API Key Errors
enum APIKeyError: Error, LocalizedError {
    case missingKey(String)
    case invalidKey(String)
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .missingKey(let key):
            return "API key '\(key)' is missing from configuration"
        case .invalidKey(let key):
            return "API key '\(key)' is invalid or malformed"
        case .configurationError:
            return "API configuration error - check your Secrets.xcconfig file"
        }
    }
}

// MARK: - APIManager Extensions for Specific Services

extension APIManager {
    
    /// Get validated OpenAI API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid OpenAI API key
    func getValidatedOpenAIKey() throws -> String {
        guard let key = openAIAPIKey else {
            throw APIKeyError.missingKey("OPENAI_API_KEY")
        }
        
        // Basic validation for OpenAI key format
        guard key.hasPrefix("sk-") && key.count > 20 else {
            throw APIKeyError.invalidKey("OPENAI_API_KEY")
        }
        
        return key
    }
    
    /// Get validated xAI API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid xAI API key
    func getValidatedXAIKey() throws -> String {
        guard let key = xaiAPIKey else {
            throw APIKeyError.missingKey("XAI_API_KEY")
        }
        
        // Basic validation for xAI key format
        guard key.hasPrefix("xai-") && key.count > 20 else {
            throw APIKeyError.invalidKey("XAI_API_KEY")
        }
        
        return key
    }

    /// Get validated Gemini API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid Gemini API key
    func getValidatedGeminiKey() throws -> String {
        guard let key = geminiAPIKey else {
            throw APIKeyError.missingKey("GEMINI_API_KEY")
        }
        // Basic validation for Google API key format (usually starts with AIza and is ~39-45 chars)
        let looksLikeGoogle = key.hasPrefix("AIza") && key.count >= 30
        guard looksLikeGoogle else {
            throw APIKeyError.invalidKey("GEMINI_API_KEY")
        }
        return key
    }

    /// Get validated Pika API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid Pika API key
    func getValidatedPikaKey() throws -> String {
        guard let key = pikaAPIKey else {
            throw APIKeyError.missingKey("PIKA_API_KEY")
        }
        // Pika keys are opaque; basic sanity check for length
        guard key.count >= 20 else {
            throw APIKeyError.invalidKey("PIKA_API_KEY")
        }
        return key
    }

    /// Get validated DeepSeek API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid DeepSeek API key
    func getValidatedDeepSeekKey() throws -> String {
        guard let key = deepseekAPIKey else {
            throw APIKeyError.missingKey("DEEPSEEK_API_KEY")
        }
        // DeepSeek uses OpenAI-compatible keys (often start with sk-)
        guard key.hasPrefix("sk-") && key.count > 20 else {
            throw APIKeyError.invalidKey("DEEPSEEK_API_KEY")
        }
        return key
    }

    /// Get validated Claude API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid Claude (Anthropic) API key
    func getValidatedClaudeKey() throws -> String {
        guard let key = claudeAPIKey else {
            throw APIKeyError.missingKey("CLAUDE_API_KEY")
        }
        // Claude keys commonly start with "sk-" or "sk-ant-"
        let looksValid = (key.hasPrefix("sk-") || key.hasPrefix("sk-ant-")) && key.count > 20
        guard looksValid else {
            throw APIKeyError.invalidKey("CLAUDE_API_KEY")
        }
        return key
    }

    /// Get validated Stability API key or throw error
    /// - Throws: APIKeyError if key is missing or invalid
    /// - Returns: Valid Stability API key
    func getValidatedStabilityKey() throws -> String {
        guard let key = stabilityAPIKey else {
            throw APIKeyError.missingKey("STABILITY_API_KEY")
        }
        // Stability keys are opaque; basic sanity check for length
        guard key.count >= 20 else {
            throw APIKeyError.invalidKey("STABILITY_API_KEY")
        }
        return key
    }
}
