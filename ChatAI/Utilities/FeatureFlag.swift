import Foundation

/// A utility for checking feature availability based on subscription status
enum ProFeatureFlag {
    // Define your pro features here
    case unlimitedChats
    case voiceInput
    case advancedModels
    case customThemes
    
    /// Check if the feature is available to the current user
    /// - Returns: Boolean indicating if the feature is available
    @MainActor
    func isAvailable() -> Bool {
        let subscriptionManager = SubscriptionManager.shared
        
        switch self {
        case .unlimitedChats, .voiceInput, .advancedModels, .customThemes:
            // These features require a pro subscription
            return subscriptionManager.isProUser
        }
    }
    
    /// Check if the feature is available and optionally show the paywall if not
    /// - Returns: Boolean indicating if the feature is available
    @MainActor
    func checkAccess() -> Bool {
        let isAvailable = isAvailable()
        if !isAvailable {
            // Show paywall for pro features
            NotificationCenter.default.post(name: .showPaywall, object: nil)
        }
        return isAvailable
    }
}

// MARK: - Example Usage
/*
// Check if a feature is available
if await ProFeatureFlag.voiceInput.isAvailable() {
    // Enable voice input
}

// Or check and show paywall if needed
if await ProFeatureFlag.voiceInput.checkAccess() {
    // Enable voice input
}
*/
