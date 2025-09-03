//
//  LoginOptionsView.swift
//  ChatAI
//
//  Second screen in login flow with auth options
//

import SwiftUI

struct LoginOptionsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack(spacing: 18) {
                Spacer()

                Text("Log in or sign up")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Button(action: { isLoggedIn = true }) {
                    Label("Continue", systemImage: "arrow.right.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Group {
                    Button(action: { isLoggedIn = true }) { Label("Continue with Apple", systemImage: "apple.logo") }.buttonStyle(SecondaryButtonStyle())
                    Button(action: { isLoggedIn = true }) { Label("Continue with Google", systemImage: "g.circle.fill") }.buttonStyle(SecondaryButtonStyle())
                    Button(action: { isLoggedIn = true }) { Label("Continue with Microsoft Account", systemImage: "m.circle.fill") }.buttonStyle(SecondaryButtonStyle())
                    Button(action: { isLoggedIn = true }) { Label("Continue with email", systemImage: "envelope.fill") }.buttonStyle(SecondaryButtonStyle())
                }

                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { LoginOptionsView() }
}
