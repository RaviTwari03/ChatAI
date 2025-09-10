//
//  ContentView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var isAuthenticated: Bool = SupabaseAuth.shared.isAuthenticated
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    var body: some View {
        NavigationStack {
            if isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Re-read tokens on app launch or when coming back from sign-out
            isAuthenticated = SupabaseAuth.shared.isAuthenticated
            // Present onboarding on first launch
            showOnboarding = !hasSeenOnboarding
        }
        .onReceive(NotificationCenter.default.publisher(for: .authStateChanged)) { _ in
            let newState = SupabaseAuth.shared.isAuthenticated
            if newState != isAuthenticated {
                print("[ContentView] authStateChanged -> isAuthenticated=\(newState)")
                isAuthenticated = newState
            } else {
                print("[ContentView] authStateChanged received but state unchanged (\(newState)).")
            }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            // Ensure we don't present again after completion
            hasSeenOnboarding = true
        }) {
            OnboardingView()
        }
    }
}

//#Preview {
//    ContentView()
//}
