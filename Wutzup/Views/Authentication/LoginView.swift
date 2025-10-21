//
//  LoginView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @StateObject private var viewModel: AuthenticationViewModel
    @State private var showRegistration = false
    
    init() {
        // Initialize with injected auth service
        let authService = FirebaseAuthService()
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Logo
                Image(systemName: "message.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Wutzup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 15) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        Task { await viewModel.login() }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 30)
                
                // Register Link
                Button(action: {
                    showRegistration = true
                }) {
                    Text("Don't have an account? **Sign Up**")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .navigationDestination(isPresented: $showRegistration) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(FirebaseAuthService())
}

