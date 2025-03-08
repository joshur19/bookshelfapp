//
//  ProfileView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 04.03.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var isEditing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isEditing {
                        EditProfileView(username: $username, displayName: $displayName, bio: $bio, isEditing: $isEditing)
                    } else {
                        ProfileInfoView(username: username, displayName: displayName, bio: bio, isEditing: $isEditing)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                    }
                    
                    if let success = successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("Logout")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private func loadUserData() {
        if let user = repository.currentUser {
            username = user.username ?? ""
            displayName = user.displayName ?? ""
            bio = user.bio ?? ""
        }
    }
}

struct ProfileInfoView: View {
    var username: String
    var displayName: String
    var bio: String
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text(displayName.isEmpty ? username : displayName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if !bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    
                    Text(bio)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            Button(action: {
                isEditing = true
            }) {
                Text("Edit Profile")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct EditProfileView: View {
    @Binding var username: String
    @Binding var displayName: String
    @Binding var bio: String
    @Binding var isEditing: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Profile")
                .font(.title)
                .fontWeight(.bold)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                
                TextField("Username", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.headline)
                
                TextField("Display Name", text: $displayName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.headline)
                
                TextEditor(text: $bio)
                    .padding(4)
                    .frame(height: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            HStack {
                Button(action: {
                    isEditing = false
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    saveProfile()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save")
                            .font(.headline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || username.isEmpty)
            }
        }
    }
    
    private func saveProfile() {
        guard !username.isEmpty else {
            errorMessage = "Username is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if let userId = authViewModel.user?.uid {
            repository.updateUserProfile(userId: userId, username: username, displayName: displayName, bio: bio) { error in
                isLoading = false
                
                if let error = error {
                    if let nsError = error as NSError?, nsError.domain == "Repository" && nsError.code == 3 {
                        errorMessage = "Username already taken. Please choose another."
                    } else {
                        errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    }
                } else {
                    isEditing = false
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
} 
