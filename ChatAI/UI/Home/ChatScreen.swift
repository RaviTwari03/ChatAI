//
//  ChatScreen.swift
//  ChatAI
//

import SwiftUI

struct ChatScreen: View {
    @State private var messages: [String] = ["Welcome 👋"]
    @State private var input: String = ""

    var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages.indices, id: \.self) { i in
                            Text(messages[i])
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                composer
            }
        }
        .navigationTitle("Chat Now ✨")
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Type a message", text: $input)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
            }
        }
        .padding(.all, 12)
        .background(.black.opacity(0.2))
    }

    private func send() {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        messages.append(t)
        input = ""
    }
}

#Preview { ChatScreen() }
