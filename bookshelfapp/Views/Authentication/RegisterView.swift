//
//  RegisterView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 22.02.25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var username: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    @Binding var successMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Create an Account")
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
            }

            VStack(spacing: 16) {
                // Email field
                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("Email")
                            .foregroundColor(Color.primary.opacity(0.6))
                            .padding()
                    }
                    
                    TextField("", text: $email)
                        .padding()
                        .foregroundColor(.primary)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .contentShape(Rectangle())
                
                // Username field
                ZStack(alignment: .leading) {
                    if username.isEmpty {
                        Text("Username")
                            .foregroundColor(Color.primary.opacity(0.6))
                            .padding()
                    }
                    
                    TextField("", text: $username)
                        .padding()
                        .foregroundColor(.primary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .contentShape(Rectangle())

                // Password field
                ZStack(alignment: .leading) {
                    if password.isEmpty {
                        Text("Password")
                            .foregroundColor(Color.primary.opacity(0.6))
                            .padding()
                    }
                    
                    SecureField("", text: $password)
                        .padding()
                        .foregroundColor(.primary)
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .contentShape(Rectangle())

                // Confirm Password field
                ZStack(alignment: .leading) {
                    if confirmPassword.isEmpty {
                        Text("Confirm Password")
                            .foregroundColor(Color.primary.opacity(0.6))
                            .padding()
                    }
                    
                    SecureField("", text: $confirmPassword)
                        .padding()
                        .foregroundColor(.primary)
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .padding(.horizontal)

            Button(action: {
                isLoading = true
                
                guard !username.isEmpty else {
                    self.errorMessage = "Username is required"
                    isLoading = false
                    return
                }
                
                guard password == confirmPassword else {
                    self.errorMessage = "Passwords do not match"
                    isLoading = false
                    return
                }
                                
                authViewModel.register(email: email, password: password) { error in
                    if let error = error {
                        errorMessage = error
                        isLoading = false
                    } else {
                        if let user = authViewModel.user {
                            // Attempt to create the user document with username
                            repository.createUser(userId: user.uid, email: email, username: username) { firestoreError in
                                if let firestoreError = firestoreError {
                                    if let nsError = firestoreError as NSError?, nsError.domain == "Repository" && nsError.code == 3 {
                                        // Username already taken
                                        errorMessage = "Username already taken. Please choose another."
                                        
                                        // Delete the auth account since we can't use this username
                                        authViewModel.deleteAuthAccount(user: user) {
                                        }
                                        isLoading = false
                                    } else {
                                        // Other Firestore error
                                        errorMessage = "Account created but failed to set up user data: \(firestoreError.localizedDescription)"
                                        print("Firestore error: \(firestoreError.localizedDescription)")
                                        
                                        // Delete the auth account since Firestore setup failed
                                        authViewModel.deleteAuthAccount(user: user) {
                                        }
                                        isLoading = false
                                    }
                                } else {
                                    // Successfully created user document and username entry, now sign out
                                    authViewModel.completeRegistration()
                                    isLoading = false
                                    successMessage = "Registration successful! Please log in."
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        } else {
                            errorMessage = "User registration failed. Please try again."
                            isLoading = false
                        }
                    }
                }
            }) {
                HStack {
                    if isLoading {
                        // Show loading spinner when registering
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    
                    Text(isLoading ? "Registering..." : "Register")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading) // Disable button when loading
            .padding(.horizontal)
            .contentShape(Rectangle()) // Add this line to make the entire button area clickable

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
        .onAppear {
            email = ""
            password = ""
            errorMessage = nil
            confirmPassword = ""
            username = ""
        }
    }
}

#Preview {
    RegisterView(successMessage: .constant("Registration successful!"))
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
}
