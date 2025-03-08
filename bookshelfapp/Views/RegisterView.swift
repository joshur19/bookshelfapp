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
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary) // Ensures text adapts to light/dark mode
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                TextField("Username", text: $username)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary) // Ensures text is visible
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary) // Ensures text is visible
                    .cornerRadius(8)
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
                            repository.createUserDocument(userId: user.uid, email: email, username: username) { firestoreError in
                                if let firestoreError = firestoreError {
                                    if let nsError = firestoreError as NSError?, nsError.domain == "Repository" && nsError.code == 3 {
                                        // Username already taken
                                        errorMessage = "Username already taken. Please choose another."
                                        
                                        // Delete the auth account since we can't use this username
                                        authViewModel.deleteAuthAccount(user: user) {
                                            // Do nothing, the account is already deleted
                                        }
                                        isLoading = false
                                    } else {
                                        // Other Firestore error
                                        errorMessage = "Account created but failed to set up user data: \(firestoreError.localizedDescription)"
                                        print("Firestore error: \(firestoreError.localizedDescription)")
                                        
                                        // Delete the auth account since Firestore setup failed
                                        authViewModel.deleteAuthAccount(user: user) {
                                            // Do nothing, the account is already deleted
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
