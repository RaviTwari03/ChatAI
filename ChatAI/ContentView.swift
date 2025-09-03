//
//  ContentView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 03/09/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        Group {
            if isLoggedIn {
                HomeTabView()
            } else {
                NavigationStack { LoginGetStartedView() }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview { ContentView() }
