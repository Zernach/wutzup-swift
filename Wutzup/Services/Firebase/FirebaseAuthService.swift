//
//  FirebaseAuthService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class FirebaseAuthService: AuthenticationService {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    var currentUser: User? {
        authStateSubject.value
    }
    
    init() {
        // Observe Firebase auth state changes
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // Fetch user from Firestore
                    do {
                        let document = try await self?.db.collection("users").document(firebaseUser.uid).getDocument()
                        if let document = document, let user = User(from: document) {
                            self?.authStateSubject.send(user)
                        }
                    } catch {
                        print("Error fetching user: \(error)")
                        self?.authStateSubject.send(nil)
                    }
                } else {
                    self?.authStateSubject.send(nil)
                }
            }
        }
    }
    
    func register(email: String, password: String, displayName: String) async throws -> User {
        // Create Firebase auth user
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Create user in Firestore
        let user = User(
            id: result.user.uid,
            email: email,
            displayName: displayName,
            createdAt: Date()
        )
        
        try await db.collection("users").document(user.id).setData(user.firestoreData)
        
        authStateSubject.send(user)
        return user
    }
    
    func login(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        
        // Fetch user from Firestore
        let document = try await db.collection("users").document(result.user.uid).getDocument()
        
        guard let user = User(from: document) else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found in Firestore"])
        }
        
        authStateSubject.send(user)
        return user
    }
    
    func logout() async throws {
        try auth.signOut()
        authStateSubject.send(nil)
    }
    
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        var updateData: [String: Any] = [:]
        if let displayName = displayName {
            updateData["displayName"] = displayName
        }
        if let profileImageUrl = profileImageUrl {
            updateData["profileImageUrl"] = profileImageUrl
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
        
        // Refresh current user
        let document = try await db.collection("users").document(userId).getDocument()
        if let user = User(from: document) {
            authStateSubject.send(user)
        }
    }
}

