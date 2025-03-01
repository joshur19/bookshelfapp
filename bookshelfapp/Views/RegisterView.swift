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
                    .background(Color.white)
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            Button(action: {
                isLoading = true
                
                guard password == confirmPassword else {
                    self.errorMessage = "Passwords do not match"
                    return
                }
                                
                authViewModel.register(email: email, password: password) { error in
                    if let error = error {
                        errorMessage = error
                        isLoading = false
                    } else {
                        if let user = authViewModel.user {
                            
                            repository.createUserDocument(userId: user.uid, email: email) { firestoreError in
                                if firestoreError != nil {
                                    errorMessage = "Account created but failed to set up user data"
                                    isLoading = false
                                } else {
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
    }
}


#Preview {
    RegisterView(successMessage: .constant("Registration successful!"))
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
}
