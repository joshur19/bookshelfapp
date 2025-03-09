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
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if isEditing {
                            EditProfileView(username: $username, displayName: $displayName, bio: $bio, isEditing: $isEditing)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            ProfileInfoView(username: username, displayName: displayName, bio: bio, isEditing: $isEditing)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        if let success = successMessage {
                            Text(success)
                                .foregroundColor(.green)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.easeInOut(duration: 0.3), value: isEditing)
                    .animation(.easeInOut, value: errorMessage)
                    .animation(.easeInOut, value: successMessage)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Profile")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !isEditing {
                        Button(action: {
                            repository.cleanUp()
                            authViewModel.logout()
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.red)
                        .help("Logout")
                    }
                }
            }
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
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Button(action: {
                    isEditing = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white).frame(width: 28, height: 28))
                }
                .offset(x: 42, y: 42)
            }
            .shadow(color: Color.blue.opacity(0.1), radius: 5, x: 0, y: 3)
            
            VStack(spacing: 6) {
                Text(displayName.isEmpty ? username : displayName)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("About")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            isEditing = true
                        }) {
                            Text("Edit")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(bio)
                        .font(.body)
                        .lineSpacing(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding(.top, 4)
            } else {
                Button(action: {
                    isEditing = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.body)
                        Text("Add Bio")
                            .font(.body)
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
                .padding(.top, 4)
            }
            
            // Wishlist Placeholder Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.text.square")
                        .foregroundColor(.pink)
                    Text("My Wishlist")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coming Soon")
                            .font(.callout)
                            .fontWeight(.medium)
                        
                        Text("Keep track of books you want to read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.top, 8)
            
            // Ratings & Reviews Placeholder Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.bubble")
                        .foregroundColor(.yellow)
                    Text("My Ratings & Reviews")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coming Soon")
                            .font(.callout)
                            .fontWeight(.medium)
                        
                        Text("Share your thoughts on books you've read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.top, 4)
        }
        .padding(.vertical)
        //.padding(.horizontal)
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
                .font(.title3)
                .fontWeight(.medium)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("Username", text: $username)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("Display Name", text: $displayName)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Bio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $bio)
                    .padding(6)
                    .frame(height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    /*.overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )*/
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    isEditing = false
                }) {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray4))
                        )
                        .foregroundColor(.white)
                }
                .contentShape(Rectangle())
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: {
                    saveProfile()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.body)
                            Text("Save")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(username.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                )
                .foregroundColor(.white)
                .shadow(color: Color.blue.opacity(0.2), radius: 3, x: 0, y: 2)
                .disabled(isLoading || username.isEmpty)
                .contentShape(Rectangle())
                .buttonStyle(ScaleButtonStyle())
            }
        }
        //.padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center)
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

// Custom button style for responsive touch feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
} 
