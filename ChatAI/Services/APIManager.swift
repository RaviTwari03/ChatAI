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
        
        if !openAIValid {
            print("❌ OpenAI API key is missing or invalid")
        }
        
        if !xaiValid {
            print("❌ xAI API key is missing or invalid")
        }
        
        return openAIValid && xaiValid
    }
    
    /// Get configuration status for debugging
    /// - Returns: Dictionary with configuration status
    func getConfigurationStatus() -> [String: Any] {
        return [
            "openAI_configured": openAIAPIKey != nil,
            "xai_configured": xaiAPIKey != nil,
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
}
