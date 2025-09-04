//
//  ChatAIApp.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI
import AuthenticationServices

@main
struct ChatAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle OAuth redirect from Supabase (e.g., chatai://auth-callback#access_token=...)
                    SupabaseAuth.shared.handleOpenURL(url)
                }
        }
    }
}
