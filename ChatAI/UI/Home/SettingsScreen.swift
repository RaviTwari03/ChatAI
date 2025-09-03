//
//  SettingsScreen.swift
//  ChatAI
//

import SwiftUI

struct SettingsScreen: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true

    var body: some View {
        ZStack {
            GradientBackgroundView()
            List {
                Section(header: Text("Account")) {
                    Text("Ravi Tiwari")
                    Button("Sign out") { isLoggedIn = false }
                        .foregroundColor(.red)
                }
                Section(header: Text("App")) {
                    Toggle("Voice Input", isOn: .constant(true))
                    Toggle("Markdown", isOn: .constant(true))
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview { SettingsScreen() }
