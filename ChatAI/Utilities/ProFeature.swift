import SwiftUI

/// A view modifier that shows a paywall when the content requires a pro subscription
struct ProFeature<Content: View>: View {
    let requiresPro: Bool
    let content: () -> Content
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    init(requiresPro: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.requiresPro = requiresPro
        self.content = content
    }
    
    var body: some View {
        Group {
            if !requiresPro || subscriptionManager.isProUser {
                content()
            } else {
                Button(action: { showPaywall = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.title)
                        Text("Pro Feature")
                            .font(.headline)
                        Text("Upgrade to Pro to unlock this feature")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
            }
        }
        .onAppear {
            // Refresh pro status when the view appears
            subscriptionManager.refreshProStatus()
        }
    }
}

// MARK: - View Extension
extension View {
    /// Wraps the view in a pro feature check
    /// - Parameter requiresPro: Whether the view requires a pro subscription
    /// - Returns: A view that shows the content or a pro upsell
    func proFeature(requiresPro: Bool) -> some View {
        ProFeature(requiresPro: requiresPro) {
            self
        }
    }
}

// MARK: - Preview
struct ProFeature_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Pro user
            Text("Pro Content")
                .proFeature(requiresPro: true)
                .environmentObject(createMockSubscriptionManager(isPro: true))
                
            // Non-pro user
            Text("Pro Content")
                .proFeature(requiresPro: true)
                .environmentObject(createMockSubscriptionManager(isPro: false))
        }
    }
    
    private static func createMockSubscriptionManager(isPro: Bool) -> SubscriptionManager {
        let manager = SubscriptionManager.shared
        manager.updateProStatus(isPro)
        return manager
    }
}
