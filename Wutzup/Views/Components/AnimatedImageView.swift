//
//  AnimatedImageView.swift
//  Wutzup
//
//  SwiftUI wrapper for UIImageView to support animated GIFs
//

import SwiftUI
import UIKit
import ImageIO

/// A SwiftUI view that displays animated images (GIFs) using UIKit's UIImageView
/// AsyncImage doesn't support GIF animation, so we need to use UIKit
struct AnimatedImageView: View {
    let url: URL?
    let cornerRadius: CGFloat

    init(
        url: URL?,
        cornerRadius: CGFloat = 8
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        if let url = url {
            AnimatedImageViewRepresentable(url: url)
                .frame(width: 200, height: 200)
                .cornerRadius(cornerRadius)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        VStack {
            Image(systemName: "photo.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No image")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 200, height: 200)
    }
}

/// UIViewRepresentable wrapper for UIImageView to support animated GIFs
private struct AnimatedImageViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
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

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize {
        // Hardcode to 200x200 square regardless of image dimensions
        return CGSize(width: 200, height: 200)
    }
}

// MARK: - UIImage GIF Extension

extension UIImage {
    /// Creates an animated UIImage from GIF data
    static func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return UIImage.animatedImageWithSource(source)
    }

    /// Creates an animated UIImage from a CGImageSource
    private static func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)

                // Get frame duration
                let frameDuration = UIImage.delayForImageAtIndex(Int(i), source: source)
                duration += frameDuration
            }
        }

        // If we couldn't extract frames, return nil
        if images.isEmpty { return nil }

        // Ensure minimum duration per frame to prevent too-fast animations
        let minDuration = 0.1
        if duration < Double(count) * minDuration {
            duration = Double(count) * minDuration
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    /// Gets the delay duration for a specific frame in a GIF
    private static func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        var delay = 0.1

        if let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
           let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {

            if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                delay = unclampedDelay.doubleValue
            } else if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                delay = delayTime.doubleValue
            }
        }

        // Ensure minimum delay (some GIFs have 0 delay which breaks animation)
        if delay < 0.01 { delay = 0.1 }
        return delay
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Animated Image View")
            .font(.headline)

        // This would display an animated GIF if a URL was provided
        AnimatedImageView(
            url: URL(string: "https://example.com/test.gif"),
            cornerRadius: 12
        )

        Text("GIF animation will play automatically")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
