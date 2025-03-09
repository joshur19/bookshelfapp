//
//  FriendProfileView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 08.03.25.
//

import SwiftUI

struct FriendProfileView: View {
    var friend: AppUser
    var books: [Book]
    var isLoading: Bool
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isRemovingFriend = false
    @State private var errorMessage: String? = nil
    @State private var showRemoveAlert = false
    
    var displayName: String {
        if let name = friend.displayName, !name.isEmpty {
            return name
        }
        return friend.username ?? "User"
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 10) {
                        // Profile Header Section
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.blue)
                            }
                            .shadow(color: Color.blue.opacity(0.1), radius: 5, x: 0, y: 3)
                            
                            VStack(spacing: 4) {
                                Text(displayName)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                if let username = friend.username {
                                    Text("@\(username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        
                        // Bio Section (if available)
                        if let bio = friend.bio, !bio.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "text.quote")
                                        .foregroundColor(.blue)
                                    Text("About")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                
                                Text(bio)
                                    .font(.body)
                                    .lineSpacing(3)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                            .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 2)
                        }
                        
                        // Error Message (if any)
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Books Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "books.vertical")
                                    .foregroundColor(.blue)
                                Text("\(displayName)'s Books")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            
                            if isLoading {
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding(.bottom, 4)
                                    
                                    Text("Loading books...")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else if books.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "books.vertical")
                                        .font(.system(size: 28))
                                        .foregroundColor(.gray.opacity(0.7))
                                    
                                    Text("No books in collection yet")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(books) { book in
                                        FriendBookView(book: book)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 2)
                        
                        // Remove Friend Button
                        Button(action: {
                            showRemoveAlert = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.minus")
                                    .font(.body)
                                
                                if isRemovingFriend {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                } else {
                                    Text("Remove Friend")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.7), lineWidth: 1.5)
                                    .background(Color.red.opacity(0.05))
                            )
                            .foregroundColor(Color.red.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.vertical, 6)
                        .disabled(isRemovingFriend)
                        .contentShape(Rectangle())

                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Friend Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showRemoveAlert) {
                Alert(
                    title: Text("Remove Friend"),
                    message: Text("Are you sure you want to remove \(displayName) from your friends?"),
                    primaryButton: .destructive(Text("Remove")) {
                        removeFriend()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func removeFriend() {
        guard let currentUserId = authViewModel.user?.uid, let friendId = friend.id else {
            errorMessage = "Unable to remove friend"
            return
        }
        
        isRemovingFriend = true
        errorMessage = nil
        
        repository.removeFriend(currentUserId: currentUserId, friendId: friendId) { error in
            isRemovingFriend = false
            
            if let error = error {
                errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct FriendBookView: View {
    var book: Book
    
    var bookColor: Color {
        return Color.color(from: book.coverColor)
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                if let thumbnailUrl = book.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .blur(radius: 2)
                            .overlay(Color.black.opacity(0.25))
                    }
                    .frame(height: 150)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bookColor)
                        .frame(height: 150)
                }
                
                VStack {
                    Text(book.title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)
                        .shadow(radius: 1)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                        .shadow(radius: 1)
                    
                    HStack(spacing: 6) {
                        if book.isCurrentlyReading {
                            Text("Reading")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                        }
                        
                        if book.isLent {
                            Text("Unavailable")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                        }
                    }
                    .padding(.top, 3)
                }
                .padding(12)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
}
