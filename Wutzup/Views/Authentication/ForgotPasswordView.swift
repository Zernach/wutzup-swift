//
//  ForgotPasswordView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData
import Combine

struct ForgotPasswordView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AuthenticationViewModel
    @State private var showSuccessMessage = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: AuthenticationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.Colors.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                ScrollView {
                    VStack(spacing: 16) {
                        Image("AppIconImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 20)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
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
                                .onSubmit {
                                    submitResetPassword()
                                }
                            
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(AppConstants.Colors.destructive)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            if showSuccessMessage {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppConstants.Colors.success)
                                    
                                    Text("Password Reset Sent!")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppConstants.Colors.textPrimary)
                                    
                                    Text("Check your email for a link to reset your password. The link will expire in 1 hour.")
                                        .font(.body)
                                        .foregroundColor(AppConstants.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 20)
                            } else {
                                Button(action: {
                                    Task { @MainActor in await submitResetPassword() }
                                }) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(AppConstants.Colors.textPrimary)
                                    } else {
                                        Text("Send Reset Link")
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
                        }
                        .padding(.horizontal, 30)
                        
                        if !showSuccessMessage {
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Back to Login")
                                    .foregroundColor(AppConstants.Colors.accent)
                                    .font(.callout)
                            }
                            .padding(.top, 12)
                        }
                    }
                    .frame(minHeight: UIScreen.main.bounds.height * 0.7)
                }
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func submitResetPassword() {
        Task { @MainActor in
            await viewModel.resetPassword()
            if viewModel.errorMessage == nil {
                showSuccessMessage = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    let previewService = PreviewAuthenticationService()
    let viewModel = AuthenticationViewModel(authService: previewService)
    // Create a minimal ModelContainer for preview
    let container = try! ModelContainer(for: UserModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let previewState = AppState(modelContainer: container)
    return ForgotPasswordView(viewModel: viewModel)
        .environmentObject(previewState)
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
    
    func resetPassword(email: String) async throws { }
}
