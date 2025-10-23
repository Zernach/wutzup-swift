//
//  ImageCache.swift
//  Wutzup
//
//  Centralized image caching system for profile images, GIFs, and other media
//

import Foundation
import UIKit
import CryptoKit

/// Centralized image cache manager that handles both in-memory and disk caching
actor ImageCache {
    static let shared = ImageCache()
    
    // MARK: - Properties
    
    /// In-memory cache for quick access
    private var memoryCache: NSCache<NSString, CachedImage>
    
    /// Disk cache directory
    private let diskCacheDirectory: URL
    
    /// Maximum age for cached items (7 days)
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60
    
    /// Maximum memory cache size (100 items)
    private let maxMemoryCacheCount = 100
    
    /// Maximum memory cache cost (100 MB)
    private let maxMemoryCacheCost = 100 * 1024 * 1024
    
    // MARK: - Initialization
    
    private init() {
        // Setup memory cache
        memoryCache = NSCache<NSString, CachedImage>()
        memoryCache.countLimit = maxMemoryCacheCount
        memoryCache.totalCostLimit = maxMemoryCacheCost
        
        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cacheDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        // Clean up old cache on initialization
        Task {
            await cleanupExpiredCache()
        }
    }
    
    // MARK: - Public Methods
    
    /// Retrieves cached image data for a given URL
    /// - Parameter url: The URL of the image
    /// - Returns: Cached image data if available, nil otherwise
    func getData(for url: URL) async -> Data? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached.data
        }
        
        // Check disk cache
        if let data = await loadFromDisk(key: key) {
            // Store in memory cache for faster access next time
            let cached = CachedImage(data: data)
            memoryCache.setObject(cached, forKey: key as NSString, cost: data.count)
            return data
        }
        
        return nil
    }
    
    /// Stores image data in cache for a given URL
    /// - Parameters:
    ///   - data: The image data to cache
    ///   - url: The URL of the image
    func setData(_ data: Data, for url: URL) async {
        let key = cacheKey(for: url)
        
        // Store in memory cache
        let cached = CachedImage(data: data)
        memoryCache.setObject(cached, forKey: key as NSString, cost: data.count)
        
        // Store on disk asynchronously
        await saveToDisk(data: data, key: key)
    }
    
    /// Loads an image from URL with caching
    /// - Parameter url: The URL to load from
    /// - Returns: Image data if successful
    func loadImage(from url: URL) async throws -> Data {
        // Check cache first
        if let cachedData = await getData(for: url) {
            return cachedData
        }
        
        // Download if not cached
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Cache the downloaded data
        await setData(data, for: url)
        
        return data
    }
    
    /// Removes cached data for a specific URL
    /// - Parameter url: The URL to remove from cache
    func removeData(for url: URL) {
        let key = cacheKey(for: url)
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk cache
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// Clears all cached data
    func clearAll() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Clears expired cache entries
    func cleanupExpiredCache() async {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        let now = Date()
        
        for fileURL in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                continue
            }
            
            // Remove if older than max age
            if now.timeIntervalSince(modificationDate) > maxCacheAge {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    /// Gets the total size of the disk cache
    /// - Returns: Total size in bytes
    func getCacheSize() async -> Int64 {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for fileURL in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    /// Preloads images from a list of URLs into the cache
    /// Useful for warming the cache with frequently accessed images
    /// - Parameter urls: Array of URLs to preload
    func preloadImages(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    // Try to load the image (will cache it if not already cached)
                    _ = try? await self.loadImage(from: url)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates a cache key from a URL
    private func cacheKey(for url: URL) -> String {
        // Use SHA256 hash of URL string as key to avoid filesystem issues with special characters
        // SHA256 ensures stable, collision-resistant hashing
        return url.absoluteString.sha256Hash
    }
    
    /// Loads data from disk cache
    private func loadFromDisk(key: String) async -> Data? {
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if file is expired
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            if Date().timeIntervalSince(modificationDate) > maxCacheAge {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }
        
        return try? Data(contentsOf: fileURL)
    }
    
    /// Saves data to disk cache
    private func saveToDisk(data: Data, key: String) async {
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Supporting Types

/// Wrapper for cached image data
private class CachedImage {
    let data: Data
    let timestamp: Date
    
    init(data: Data) {
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - String Extension for SHA256 Hashing

extension String {
    /// Generates a SHA256 hash of the string for cache key generation
    /// Uses CryptoKit to ensure stable, collision-resistant hashing
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

