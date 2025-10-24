//
//  UserService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

protocol UserService: AnyObject {
    func fetchAllUsers() async throws -> [User]
    func fetchUser(userId: String) async throws -> User
    func updatePersonality(userId: String, personality: String?) async throws
    func updateProfileImageUrl(userId: String, imageUrl: String?) async throws
    func updateLanguages(userId: String, primaryLanguageCode: String?, learningLanguageCode: String?) async throws
}
