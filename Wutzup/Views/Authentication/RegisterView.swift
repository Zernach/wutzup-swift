//
//  RegisterView.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: FirebaseAuthService
    @StateObject private var viewModel: AuthenticationViewModel
    
    init() {
        // Initialize with injected auth service
        let authService = FirebaseAuthService()
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Logo
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            // Registration Form
            VStack(spacing: 15) {
                TextField("Display Name", text: $viewModel.displayName)
                    .textContentType(.name)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task { await viewModel.register() }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
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
            
            // Back to Login
            Button(action: {
                dismiss()
            }) {
                Text("Already have an account? **Log In**")
                    .foregroundColor(.blue)
            }
            .padding(.top, 10)
            
            Spacer()
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
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(FirebaseAuthService())
    }
}

