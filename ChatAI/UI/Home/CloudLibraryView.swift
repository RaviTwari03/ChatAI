//
//  CloudLibraryView.swift
//  ChatAI
//
//  Shows user's generated images stored in Supabase Storage using the
//  URLs recorded in the `user_images` table.
//

import SwiftUI

struct CloudLibraryView: View {
    var onPick: ((Data, String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var urls: [String] = []
    @State private var isLoading = true
    @State private var error: String? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Title bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left").foregroundColor(.white)
                    }
                    Text("Library")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if isLoading {
                    ProgressView("Loading…").tint(.white).padding()
                } else if let e = error {
                    VStack(spacing: 10) {
                        Text(e).foregroundColor(.white)
                        Button("Retry") { Task { await load() } }
                    }
                    .padding()
                } else if urls.isEmpty {
                    Text("No images yet").foregroundColor(.white.opacity(0.8)).padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(urls, id: \.self) { url in
                                CloudImageTile(url: url) { data in
                                    if let onPick, let data { onPick(data, "image/jpeg") }
                                }
                            }
                        }
                        .padding(8)
                    }
                }

                // Bottom generate button (optional)
                if onPick == nil { // show only when not returning data
                    Button(action: { /* hook to your generator screen if desired */ }) {
                        Text("Generate Image")
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .onAppear { Task { await load() } }
        .preferredColorScheme(.dark)
    }

    private func load() async {
        isLoading = true
        error = nil
        guard let uid = await SupabaseAuth.shared.userId else {
            await MainActor.run {
                self.urls = []
                self.isLoading = false
            }
            return
        }
        let res = await SupabaseService().fetchUserImages(userId: uid, limit: 60)
        await MainActor.run {
            switch res {
            case .success(let list):
                self.urls = list
                self.isLoading = false
            case .failure(let err):
                self.error = err.localizedDescription
                self.isLoading = false
            }
        }
    }
}

private struct CloudImageTile: View {
    let url: String
    var onPick: (Data?) -> Void
    @State private var ui: UIImage? = nil
    @State private var loading = true

    var body: some View {
        ZStack {
            if let img = ui {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.white.opacity(0.08)
                ProgressView().tint(.white)
            }
        }
        .frame(height: 110)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            if let img = ui, let data = img.jpegData(compressionQuality: 0.9) {
                onPick(data)
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        guard let u = URL(string: url) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: u)
            if let img = UIImage(data: data) {
                await MainActor.run { self.ui = img }
            }
        } catch {
            // Ignore tile errors
        }
    }
}
