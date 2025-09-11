//
//  CloudLibraryView.swift
//  ChatAI
//
//  Shows user's generated images stored in Supabase Storage using the
//  URLs recorded in the `user_images` table.
//

import SwiftUI
import Photos
import UIKit

struct CloudLibraryView: View {
    var onPick: ((Data, String) -> Void)? = nil // ignored in this standalone screen per request
    @Environment(\.dismiss) private var dismiss
    @State private var urls: [String] = []
    @State private var isLoading = true
    @State private var error: String? = nil
    @State private var previewImage: UIImage? = nil
    @State private var showPreview: Bool = false
    @State private var selectedURL: String? = nil
    @State private var showGenerateSheet: Bool = false
    @State private var promptText: String = ""
    @State private var isGenerating: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            neonBackdropView().ignoresSafeArea()
            VStack(spacing: 0) {
                if isLoading {
                    VStack { ProgressView("Loading…").tint(.white) }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let e = error {
                    VStack(spacing: 10) {
                        Text(e).foregroundColor(.white)
                        Button("Retry") { Task { await load() } }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if urls.isEmpty {
                    VStack {
                        Text("No images yet")
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(urls, id: \.self) { url in
                                CloudImageTile(url: url) { tappedURL, data in
                                    selectedURL = tappedURL
                                    if let data, let img = UIImage(data: data) {
                                        previewImage = img
                                        showPreview = true
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                }

                // Bottom generate button (optional)
                if onPick == nil { // show only when not returning data
                    Button(action: { showGenerateSheet = true }) {
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
        .sheet(isPresented: $showPreview) {
            ZStack {
                neonBackdropView().ignoresSafeArea()
                if let img = previewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                // Top close
                VStack { HStack { Button(action: { showPreview = false }) { Image(systemName: "xmark.circle.fill").foregroundColor(.white).font(.title2) }; Spacer() }.padding(); Spacer() }
                // Bottom action bar
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: { if let img = previewImage { saveToPhotos(img) } }) {
                            labelButton(title: "Save to Photos", system: "square.and.arrow.down")
                        }
                        Button(action: { if let img = previewImage { shareImage(img) } }) {
                            labelButton(title: "Share", system: "square.and.arrow.up")
                        }
                        Button(role: .destructive, action: { Task { await deleteCurrent() } }) {
                            labelButton(title: "Delete", system: "trash")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showGenerateSheet) { generateSheet }
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

    // MARK: - Preview action helpers (inside View scope)
    private func saveToPhotos(_ image: UIImage) {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
                return
            }
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func shareImage(_ image: UIImage) {
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        // Present from the first key window's root if possible
        let rootVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController
        rootVC?.present(vc, animated: true)
    }

    private func deleteCurrent() async {
        guard let url = selectedURL else { return }
        let res = await SupabaseService().deleteUserImageByPublicURL(url)
        await MainActor.run {
            if case .success = res {
                urls.removeAll { $0 == url }
                showPreview = false
                selectedURL = nil
            }
        }
    }

    @ViewBuilder
    private func labelButton(title: String, system: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: system)
            Text(title)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.14)))
    }

    private var generateSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Describe the image you want to create")
                    .foregroundColor(.white)
                TextField("A cute orange kitten with blue eyes", text: $promptText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .tint(.white)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    Task { await generateImage() }
                } label: {
                    HStack { Spacer(); Text(isGenerating ? "Generating…" : "Generate").bold(); Spacer() }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.18)))
                }
                .disabled(isGenerating || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(neonBackdropView().ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showGenerateSheet = false } }
                ToolbarItem(placement: .principal) { Text("Generate Image").foregroundColor(.white) }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func generateImage() async {
        let clean = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        await MainActor.run { isGenerating = true }
        do {
            let data = try await APIRegistry.shared.generateImage(prompt: clean, size: "1024x1024")
            let up = await SupabaseService().uploadGeneratedImage(data: data)
            switch up {
            case .success(let url):
                let _ = await SupabaseService().insertUserImage(url: url)
                await MainActor.run {
                    urls.insert(url, at: 0)
                    showGenerateSheet = false
                    promptText = ""
                }
            case .failure:
                break
            }
        } catch {
            // TODO: Show an alert if desired
        }
        await MainActor.run { isGenerating = false }
    }
}

private struct CloudImageTile: View {
    let url: String
    var onPick: (String, Data?) -> Void
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
                onPick(url, data)
            } else {
                onPick(url, nil)
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

// MARK: - Shared neon backdrop used for empty/loading states
private func neonBackdropView() -> some View {
    ZStack {
        LinearGradient(colors: [Color.black, Color(red: 0.02, green: 0.03, blue: 0.06)], startPoint: .top, endPoint: .bottom)
        RadialGradient(colors: [Color.purple.opacity(0.45), .clear], center: .topTrailing, startRadius: 40, endRadius: 520)
            .blur(radius: 28)
            .offset(x: 60, y: -30)
            .blendMode(.plusLighter)
        RadialGradient(colors: [Color.green.opacity(0.4), .clear], center: .bottomLeading, startRadius: 60, endRadius: 500)
            .blur(radius: 28)
            .offset(x: -60, y: 160)
            .blendMode(.plusLighter)
    }
}
