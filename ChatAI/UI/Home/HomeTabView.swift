//
//  HomeTabView.swift
//  ChatAI
//
//  Root after login: tabs for Home/Chat/Library/Settings
//

import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            DiscoverHomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ChatScreen()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            LibraryScreen()
                .tabItem { Label("Library", systemImage: "square.stack.fill") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.white)
    }
}

#Preview { HomeTabView() }
