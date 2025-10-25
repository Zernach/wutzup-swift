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
class FirebaseAuthService: AuthenticationService, ObservableObject {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    // Track whether Firebase has completed its initial auth check
    private let isAuthCheckingSubject = CurrentValueSubject<Bool, Never>(true)
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> {
        isAuthCheckingSubject.eraseToAnyPublisher()
    }
    
    var currentUser: User? {
        authStateSubject.value
    }
    
    init() {
        // Observe Firebase auth state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Mark that we're checking auth
                self.isAuthCheckingSubject.send(true)
                
                guard let firebaseUser = firebaseUser else {
                    // No user - auth check complete
                    self.authStateSubject.send(nil)
                    self.isAuthCheckingSubject.send(false)
                    return
                }
                
                do {
                    let user = try await self.ensureUserDocument(for: firebaseUser)
                    self.authStateSubject.send(user)
                    // User loaded - auth check complete
                    self.isAuthCheckingSubject.send(false)
                } catch {
                    self.authStateSubject.send(nil)
                    // Error occurred - auth check complete (treat as no user)
                    self.isAuthCheckingSubject.send(false)
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
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
        
        let persistedUser = try await ensureUserDocument(
            for: result.user,
            emailOverride: email,
            displayNameOverride: displayName
        )
        
        authStateSubject.send(persistedUser)
        return persistedUser
    }
    
    func login(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        
        let user = try await ensureUserDocument(for: result.user, emailOverride: email)
        
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
    
    func deleteAccount() async throws {
        guard let firebaseUser = auth.currentUser else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        let userId = firebaseUser.uid
        
        // Delete user document from Firestore
        try await db.collection("users").document(userId).delete()
        
        // Delete Firebase Auth user
        try await firebaseUser.delete()
        
        // Clear auth state
        authStateSubject.send(nil)
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    private func ensureUserDocument(for authUser: FirebaseAuth.User, emailOverride: String? = nil, displayNameOverride: String? = nil) async throws -> User {
        let userRef = db.collection("users").document(authUser.uid)
        let snapshot = try await userRef.getDocument()
        
        if let existing = User(from: snapshot) {
            return existing
        }
        
        let fallbackUser = makeFallbackUser(
            for: authUser,
            emailOverride: emailOverride,
            displayNameOverride: displayNameOverride
        )
        
        try await userRef.setData(fallbackUser.firestoreData, merge: true)
        return fallbackUser
    }
    
    private func makeFallbackUser(for authUser: FirebaseAuth.User, emailOverride: String?, displayNameOverride: String?) -> User {
        let resolvedEmail = resolveEmail(for: authUser, override: emailOverride)
        let resolvedDisplayName = resolveDisplayName(
            for: authUser,
            email: resolvedEmail,
            override: displayNameOverride
        )
        let createdAt = authUser.metadata.creationDate ?? Date()
        
        return User(
            id: authUser.uid,
            email: resolvedEmail,
            displayName: resolvedDisplayName,
            createdAt: createdAt
        )
    }
    
    private func resolveEmail(for authUser: FirebaseAuth.User, override: String?) -> String {
        if let override = override, !override.isEmpty {
            return override
        }
        if let email = authUser.email, !email.isEmpty {
            return email
        }
        if let providerEmail = authUser.providerData.first?.email, !providerEmail.isEmpty {
            return providerEmail
        }
        return "\(authUser.uid)@wutzup.app"
    }
    
    private func resolveDisplayName(for authUser: FirebaseAuth.User, email: String, override: String?) -> String {
        if let override = override, !override.isEmpty {
            return override
        }
        if let displayName = authUser.displayName, !displayName.isEmpty {
            return displayName
        }
        if let nameFromEmail = email.split(separator: "@").first, !nameFromEmail.isEmpty {
            return String(nameFromEmail)
        }
        return "User \(authUser.uid.prefix(6))"
    }
}
