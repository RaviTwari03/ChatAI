//
//  ChatAIApp.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
import AuthenticationServices
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var showPaywall = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe auth state changes
        NotificationCenter.default.publisher(for: .authStateChanged)
            .sink { [weak self] _ in
                // Refresh subscription status when auth state changes
                SubscriptionManager.shared.refreshProStatus()
            }
            .store(in: &cancellables)
        
        // Observe paywall presentation requests
        NotificationCenter.default.publisher(for: .showPaywall)
            .sink { [weak self] _ in
                self?.showPaywall = true
            }
            .store(in: &cancellables)
    }
}

@main
struct ChatAIApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle OAuth redirect from Supabase (e.g., chatai://auth-callback#access_token=...)
                    SupabaseAuth.shared.handleOpenURL(url)
                }
                .sheet(isPresented: $appState.showPaywall) {
                    // Present the paywall view when needed
                    PaywallView()
                }
        }
    }
}
