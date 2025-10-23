//
//  FirebaseUserService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FirebaseUserService: UserService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func fetchAllUsers() async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        let users = snapshot.documents.compactMap { User(from: $0) }
        return users
    }
    
    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = User(from: document) else {
            throw NSError(
                domain: "FirebaseUserService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"]
            )
        }
        
        return user
    }
    
    func updatePersonality(userId: String, personality: String?) async throws {
        var updateData: [String: Any] = [:]
        
        if let personality = personality {
            updateData["personality"] = personality
        } else {
            updateData["personality"] = FieldValue.delete()
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
    }
    
    func updateProfileImageUrl(userId: String, imageUrl: String?) async throws {
        var updateData: [String: Any] = [:]
        
        if let imageUrl = imageUrl {
            updateData["profileImageUrl"] = imageUrl
        } else {
            updateData["profileImageUrl"] = FieldValue.delete()
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
    }
    
    // MARK: - Image Upload
    
    /// Uploads a profile image to Firebase Storage and returns the download URL
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - image: The image to upload
    /// - Returns: The download URL of the uploaded image
    func uploadProfileImage(userId: String, image: UIImage) async throws -> String {
        // Compress image to reasonable size (max 1MB, 80% quality)
        guard let imageData = compressImage(image, maxSizeKB: 1024) else {
            throw NSError(
                domain: "FirebaseUserService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]
            )
        }
        
        // Create storage reference
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "profile_\(timestamp).jpg"
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("profile")
            .child(filename)
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload image
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    /// Compresses an image to fit within a maximum file size
    /// - Parameters:
    ///   - image: The image to compress
    ///   - maxSizeKB: Maximum file size in kilobytes
    /// - Returns: Compressed image data, or nil if compression failed
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Iteratively reduce quality if needed
        while let data = imageData, data.count > maxBytes, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        // If still too large, resize the image
        if let data = imageData, data.count > maxBytes {
            let ratio = sqrt(CGFloat(maxBytes) / CGFloat(data.count))
            let newSize = CGSize(
                width: image.size.width * ratio,
                height: image.size.height * ratio
            )
            
            let resizedImage = resizeImage(image, to: newSize)
            imageData = resizedImage?.jpegData(compressionQuality: 0.8)
        }
        
        return imageData
    }
    
    /// Resizes an image to a new size
    /// - Parameters:
    ///   - image: The image to resize
    ///   - size: The target size
    /// - Returns: Resized image, or nil if resizing failed
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
