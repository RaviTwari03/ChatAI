//
//  LibraryScreen.swift
//  ChatAI
//

import SwiftUI

struct LibraryScreen: View {
    var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack(spacing: 16) {
                Text("Library")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Your files, links, and audio live here.")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

#Preview { LibraryScreen() }
