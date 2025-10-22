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
}
