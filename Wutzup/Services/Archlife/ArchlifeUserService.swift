import Foundation
import UIKit

final class ArchlifeUserService: UserService {
    func fetchAllUsers() async throws -> [User] { try await fetchUsers(isTutor: nil) }
    func fetchUsers(isTutor: Bool?) async throws -> [User] {
        var users: [User] = [], after: String?
        repeat {
            var input: [String: Any] = ["limit": 200]
            if let isTutor { input["isTutor"] = isTutor }
            if let after { input["after"] = after }
            let result: WutzupUsersResult = try await ArchlifeWutzupAPI.data("users", input)
            users += result.users
            after = result.next
        } while after != nil
        return users
    }
    func fetchUser(userId: String) async throws -> User {
        let result: WutzupUserResult = try await ArchlifeWutzupAPI.data("user", ["id": userId])
        return result.user
    }
    private func update(_ userId: String, _ fields: [String: Any]) async throws {
        try ArchlifeWutzupAPI.requireActor(userId)
        let _: WutzupUserResult = try await ArchlifeWutzupAPI.data("profile", fields)
    }
    func updatePersonality(userId: String, personality: String?) async throws {
        try await update(userId, ["personality": personality as Any? ?? NSNull()])
    }
    func updateProfileImageUrl(userId: String, imageUrl: String?) async throws {
        try await update(userId, ["profileImageUrl": imageUrl as Any? ?? NSNull()])
    }
    func updateLanguages(userId: String, primaryLanguageCode: String?, learningLanguageCode: String?) async throws {
        try await update(userId, ["primaryLanguageCode": primaryLanguageCode as Any? ?? NSNull(), "learningLanguageCode": learningLanguageCode as Any? ?? NSNull()])
    }
    func uploadProfileImage(userId: String, image: UIImage) async throws -> String {
        try ArchlifeWutzupAPI.requireActor(userId)
        let scale = min(1, 1024 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let bytes = resized.jpegData(compressionQuality: 0.8), bytes.count <= 5 * 1024 * 1024 else { throw WutzupAPIError(status: 400, code: "invalid_media") }
        var request = URLRequest(url: URL(string: ArchlifeWutzupAPI.baseURL + "/media")!)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = bytes
        let (data, response) = try await ArchlifeWutzupAPI.send(request)
        return try WutzupWire.decode(WutzupMediaResult.self, data: data, response: response).url
    }
}
