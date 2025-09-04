//
//  ContentView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated: Bool = SupabaseAuth.shared.isAuthenticated
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
        }
    }
}

#Preview {
    ContentView()
}
