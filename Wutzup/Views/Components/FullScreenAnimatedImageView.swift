//
//  FullScreenAnimatedImageView.swift
//  Wutzup
//
//  Full-screen animated image viewer with dismiss gesture
//

import SwiftUI

struct FullScreenAnimatedImageView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Black background
                    Color.black
                        .ignoresSafeArea()
                    
                    // Animated image with zoom and pan gestures
                    AnimatedImageViewRepresentable(url: url)
                        .frame(maxWidth: geometry.size.width - 40, maxHeight: geometry.size.height - 40)
                        .padding(20)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), 4.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation(.spring()) {
                                        if scale > 1.0 {
                                            scale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        } else {
                                            scale = 2.0
                                        }
                                    }
                                }
                        )
                        .clipped()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
    }
}

/// UIViewRepresentable wrapper for UIImageView to support animated GIFs in full screen
private struct AnimatedImageViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Load image data asynchronously with caching
        Task {
            do {
                // Try to load from cache first, then download if needed
                let data = try await ImageCache.shared.loadImage(from: url)

                // Create animated image on main thread
                await MainActor.run {
                    if let image = UIImage.gifImageWithData(data) {
                        uiView.image = image
                    }
                }
            } catch {
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FullScreenAnimatedImageView(url: URL(string: "https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif")!)
}

