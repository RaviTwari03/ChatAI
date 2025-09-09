import Foundation
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var isProUser: Bool = false
    
    /// Updates the pro user status (for testing/mocking purposes)
    func updateProStatus(_ isPro: Bool) {
        self.isProUser = isPro
    }
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error? = nil
    
    private let supabaseService = SupabaseService()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to auth state changes to update pro status when user logs in/out
        NotificationCenter.default.publisher(for: .authStateChanged)
            .sink { [weak self] _ in
                self?.refreshProStatus()
            }
            .store(in: &cancellables)
        
        // Initial refresh
        refreshProStatus()
    }
    
    /// Refreshes the pro status from Supabase
    func refreshProStatus() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            let isPro = await supabaseService.checkProStatus()
            await MainActor.run {
                self.isProUser = isPro
                self.isLoading = false
            }
        }
    }
    
    /// Checks if a feature is available based on the user's subscription
    /// - Parameter requiresPro: Whether the feature requires a pro subscription
    /// - Returns: Boolean indicating if the feature is available
    func isFeatureAvailable(requiresPro: Bool) -> Bool {
        return !requiresPro || isProUser
    }
    
    /// Shows a paywall if the feature requires pro and user is not pro
    /// - Parameter requiresPro: Whether the feature requires pro
    /// - Returns: Boolean indicating if the feature is available
    func checkFeatureAccess(requiresPro: Bool) -> Bool {
        if requiresPro && !isProUser {
            // Show paywall
            NotificationCenter.default.post(name: .showPaywall, object: nil)
            return false
        }
        return true
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let authStateChanged = Notification.Name("AuthStateChanged")
    static let showPaywall = Notification.Name("ShowPaywall")
    static let proStatusUpdated = Notification.Name("ProStatusUpdated")
}
