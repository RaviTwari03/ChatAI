//
//  GradientBackgroundView.swift
//  ChatAI
//
//  Shared background used across screens
//

import SwiftUI

struct GradientBackgroundView: View {
    var body: some View {
        ZStack {
            // Base dark background
            LinearGradient(colors: [Color.black, Color.black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Soft blurred blobs to match neon vibe
            ZStack {
                RadialGradient(colors: [Color.green.opacity(0.35), .clear], center: .top, startRadius: 10, endRadius: 350)
                    .blur(radius: 40)
                    .offset(y: -80)

                RadialGradient(colors: [Color.purple.opacity(0.35), .clear], center: .topTrailing, startRadius: 10, endRadius: 320)
                    .blur(radius: 50)
                    .offset(x: 80, y: -40)

                RadialGradient(colors: [Color.blue.opacity(0.25), .clear], center: .center, startRadius: 10, endRadius: 420)
                    .blur(radius: 60)
                    .opacity(0.8)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    GradientBackgroundView()
}
