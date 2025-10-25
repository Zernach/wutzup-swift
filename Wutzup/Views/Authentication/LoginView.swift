//
//  LoginView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI
import SwiftData
import Combine

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AuthenticationViewModel
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    
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
                    VStack(spacing: 24) {
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.top, 80)
                    
                    Text("Wutzup International")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text("Language Learning Powered by AI")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
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
                        
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
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
                                submitLoginFromPasswordField()
                            }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(AppConstants.Colors.destructive)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            Task { @MainActor in await viewModel.login() }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(AppConstants.Colors.textPrimary)
                            } else {
                                Text("Log In")
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
                        showForgotPassword = true
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(AppConstants.Colors.accent)
                            .font(.callout)
                    }
                    .padding(.top, 6)
                    
                    Button(action: {
                        showRegistration = true
                    }) {
                        Text("Don't have an account? **Sign Up**")
                            .foregroundColor(AppConstants.Colors.accent)
                            .font(.callout)
                    }
                    .padding(.top, 6)
                    
                    Spacer()
                    }
                    .frame(minHeight: UIScreen.main.bounds.height)
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(isPresented: $showRegistration) {
                RegisterView(viewModel: appState.makeAuthenticationViewModel())
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView(viewModel: appState.makeAuthenticationViewModel())
            }
        }
    }
    
    private func submitLoginFromPasswordField() {
        let trimmedPassword = viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else { return }
        
        Task { @MainActor in await viewModel.login() }
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
    return LoginView(viewModel: viewModel)
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
