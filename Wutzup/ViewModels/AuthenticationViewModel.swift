//
//  AuthenticationViewModel.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func login() async {
        guard validateLoginInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.login(email: email, password: password)
            // Success - AppState will handle navigation
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register() async {
        guard validateRegistrationInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.register(email: email, password: password, displayName: displayName)
            // Success - AppState will handle navigation
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard validateEmailInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
            // Success - show success message
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func validateLoginInput() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email"
            return false
        }
        
        return true
    }
    
    private func validateEmailInput() -> Bool {
        if email.isEmpty {
            errorMessage = "Please enter your email"
            return false
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email"
            return false
        }
        
        return true
    }
    
    private func validateRegistrationInput() -> Bool {
        if email.isEmpty || password.isEmpty || displayName.isEmpty {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        if displayName.count < 2 {
            errorMessage = "Display name must be at least 2 characters"
            return false
        }
        
        return true
    }
}

