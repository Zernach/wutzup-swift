import Foundation
import FirebaseAuth
import Combine
import UIKit

/// Firebase handles sign-in, password reset and identity deletion. Profiles live in Archlife.
@MainActor
final class FirebaseAuthService: AuthenticationService, ObservableObject {
    private let auth = Auth.auth()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var profileTask: Task<Void, Never>?
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    private let isAuthCheckingSubject = CurrentValueSubject<Bool, Never>(true)
    var authStatePublisher: AnyPublisher<User?, Never> { authStateSubject.eraseToAnyPublisher() }
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> { isAuthCheckingSubject.eraseToAnyPublisher() }
    var currentUser: User? { authStateSubject.value }
    init() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }
                self.profileTask?.cancel()
                guard let firebaseUser else {
                    self.authStateSubject.send(nil)
                    self.isAuthCheckingSubject.send(false)
                    return
                }
                self.isAuthCheckingSubject.send(true)
                self.profileTask = Task { @MainActor in
                    do {
                        let user = try await self.ensureProfile(firebaseUser)
                        guard !Task.isCancelled, self.auth.currentUser?.uid == firebaseUser.uid else { return }
                        self.authStateSubject.send(user)
                    } catch {
                        guard !Task.isCancelled, self.auth.currentUser?.uid == firebaseUser.uid else { return }
                        // Identity remains signed in while the API is temporarily unavailable.
                        self.authStateSubject.send(User(id: firebaseUser.uid, email: firebaseUser.email ?? "", displayName: firebaseUser.displayName ?? "User"))
                    }
                    self.isAuthCheckingSubject.send(false)
                }
            }
        }
    }
    deinit { profileTask?.cancel(); if let handle = authStateListenerHandle { auth.removeStateDidChangeListener(handle) } }
    private func ensureProfile(_ user: FirebaseAuth.User, name: String? = nil) async throws -> User {
        let displayName = name ?? user.displayName ?? user.email?.split(separator: "@").first.map(String.init) ?? "User"
        let result: WutzupUserResult = try await ArchlifeWutzupAPI.data("bootstrap", ["displayName": displayName])
        return result.user
    }
    func register(email: String, password: String, displayName: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        let change = result.user.createProfileChangeRequest()
        change.displayName = displayName
        try await change.commitChanges()
        _ = try await ensureProfile(result.user, name: displayName)
        let persisted: WutzupUserResult = try await ArchlifeWutzupAPI.data("profile", ["displayName": displayName])
        authStateSubject.send(persisted.user)
        return persisted.user
    }
    func login(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        let user = try await ensureProfile(result.user)
        authStateSubject.send(user)
        return user
    }
    func logout() async throws {
        if let token = UserDefaults.standard.string(forKey: "wutzup.apns.deviceToken") {
            let _: WutzupOK? = try? await ArchlifeWutzupAPI.data("device_unregister", ["token": token])
        }
        UIApplication.shared.unregisterForRemoteNotifications()
        try auth.signOut()
        authStateSubject.send(nil)
    }
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws {
        var input: [String: Any] = [:]
        if let displayName { input["displayName"] = displayName }
        if let profileImageUrl { input["profileImageUrl"] = profileImageUrl }
        let result: WutzupUserResult = try await ArchlifeWutzupAPI.data("profile", input)
        authStateSubject.send(result.user)
    }
    func deleteAccount() async throws {
        guard let user = auth.currentUser else { throw WutzupAPIError(status: 401, code: "unauthorized") }
        let _: WutzupOK = try await ArchlifeWutzupAPI.data("delete_account")
        try await user.delete()
        authStateSubject.send(nil)
    }
    func resetPassword(email: String) async throws { try await auth.sendPasswordReset(withEmail: email) }
}
