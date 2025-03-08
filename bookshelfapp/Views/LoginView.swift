//
//  Login.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 22.02.25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoggingIn: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Text("Welcome Back")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                } else if let message = successMessage {
                    Text(message)
                        .foregroundColor(.green)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                Button(action: {
                    login()
                }) {
                    if isLoggingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .font(.headline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isLoggingIn)

                NavigationLink("Don't have an account? Register", destination: RegisterView(successMessage: $successMessage).environmentObject(repository))
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 16)

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
            .onAppear {
                email = ""
                password = ""
                errorMessage = nil
            }
        }
    }
    
    private func login() {
        isLoggingIn = true
        errorMessage = nil
        
        authViewModel.login(email: email, password: password) { error in
            isLoggingIn = false
            
            if let error = error {
                errorMessage = error
            } else {
                successMessage = "Login successful!"
                
                // Fetch user data after successful login
                if let userId = authViewModel.user?.uid {
                    repository.fetchCurrentUser(userId: userId)
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
}
