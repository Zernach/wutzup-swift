//
//  CachedAsyncImage.swift
//  Wutzup
//
//  A SwiftUI view that loads and caches remote images
//

import SwiftUI

/// A view that asynchronously loads and caches images from a URL
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data = try await ImageCache.shared.loadImage(from: url)
            
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = uiImage
                }
            }
        } catch {
        }
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    /// Creates a cached async image with default placeholder
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in
                image
                    .resizable()
            },
            placeholder: {
                Color.gray.opacity(0.3)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Cached Async Image")
            .font(.headline)
        
        CachedAsyncImage(url: URL(string: "https://picsum.photos/200")) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ProgressView()
                .frame(width: 200, height: 200)
        }
        .frame(width: 200, height: 200)
        .clipShape(Circle())
        
        Text("Image is cached for reuse")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

