//
//  RegisterView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import Combine

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AuthenticationViewModel
    
    init(viewModel: AuthenticationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            AppConstants.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(AppConstants.Colors.accent)
                
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                Spacer()
                
                VStack(spacing: 16) {
                    TextField("Display Name", text: $viewModel.displayName)
                        .textContentType(.name)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(AppConstants.Colors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppConstants.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .tint(AppConstants.Colors.accent)
                    
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(AppConstants.Colors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppConstants.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .tint(AppConstants.Colors.accent)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .submitLabel(.go)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(AppConstants.Colors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppConstants.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                        .tint(AppConstants.Colors.accent)
                        .onSubmit {
                            submitRegistrationFromPasswordField()
                        }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(AppConstants.Colors.destructive)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        Task { @MainActor in await viewModel.register() }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppConstants.Colors.textPrimary)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConstants.Colors.accent)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                    .cornerRadius(12)
                    .disabled(viewModel.isLoading)
                    .shadow(color: AppConstants.Colors.accent.opacity(0.35), radius: 12, y: 4)
                }
                .padding(.horizontal, 30)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Already have an account? **Log In**")
                        .foregroundColor(AppConstants.Colors.accent)
                        .font(.callout)
                }
                .padding(.top, 6)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .tint(AppConstants.Colors.accent)
            }
        }
    }
    
    private func submitRegistrationFromPasswordField() {
        let trimmedPassword = viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else { return }
        
        Task { @MainActor in await viewModel.register() }
    }
}

#Preview {
    NavigationStack {
        let previewService = PreviewAuthenticationService()
        let viewModel = AuthenticationViewModel(authService: previewService)
        RegisterView(viewModel: viewModel)
    }
}

private final class PreviewAuthenticationService: AuthenticationService {
    var authStatePublisher: AnyPublisher<User?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
    
    var isAuthCheckingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
    
    var currentUser: User? { nil }
    
    func register(email: String, password: String, displayName: String) async throws -> User {
        User(id: UUID().uuidString, email: email, displayName: displayName)
    }
    
    func login(email: String, password: String) async throws -> User {
        User(id: UUID().uuidString, email: email, displayName: "Preview")
    }
    
    func logout() async throws { }
    
    func updateProfile(displayName: String?, profileImageUrl: String?) async throws { }
    
    func deleteAccount() async throws { }
}
