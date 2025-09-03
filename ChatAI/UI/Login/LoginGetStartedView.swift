//
//  LoginGetStartedView.swift
//  ChatAI
//
//  First screen in login flow
//

import SwiftUI

struct LoginGetStartedView: View {
    var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Get Started")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Text("Create, Explore, Be Inspired")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 32)

                NavigationLink {
                    LoginOptionsView()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack(spacing: 16) {
                    Text("Terms")
                    Text("Privacy")
                    Text("Help")
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom)

                Spacer(minLength: 40)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack { LoginGetStartedView() }
}
