//
//  AuthenticationService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import Combine

protocol AuthenticationService: AnyObject {
    var authStatePublisher: AnyPublisher<User?, Never> { get }
    var currentUser: User? { get }
    
    func register(email: String, password: String, displayName: String) async throws -> User
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws
}

