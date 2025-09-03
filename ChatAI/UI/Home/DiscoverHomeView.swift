//
//  DiscoverHomeView.swift
//  ChatAI
//
//  Main landing with chips and gradient background
//

import SwiftUI

struct DiscoverHomeView: View {
    @State private var input: String = ""
    @State private var mode: Mode = .text

    enum Mode: String, CaseIterable { case text = "Text", files = "Files", web = "Web Link", audio = "Audio", voice = "Voice" }

    var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack(spacing: 16) {
                header
                chips
                Spacer()
                composer
            }
            .padding(.horizontal)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create, Explore,\nBe Inspired")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Welcome • Ready to start?")
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Mode.allCases, id: \.self) { m in
                    Text(m.rawValue)
                        .chip()
                        .overlay(
                            Capsule().stroke(m == mode ? Color.white.opacity(0.8) : .clear, lineWidth: 1)
                        )
                        .onTapGesture { mode = m }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Chat now ✍️", text: $input)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                Button(action: {}) { Image(systemName: "paperclip") }
                    .foregroundColor(.white)
                Button(action: {}) { Image(systemName: "mic.fill") }
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack {
                Button("Files") {}
                    .buttonStyle(SecondaryButtonStyle())
                Button("Web Link") {}
                    .buttonStyle(SecondaryButtonStyle())
                Button("Audio") {}
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.bottom, 24)
    }
}

#Preview { DiscoverHomeView() }
