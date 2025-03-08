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
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text(friend.displayName ?? friend.username ?? "User")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let username = friend.username {
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        if let bio = friend.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 5)
                        }
                        
                        Button(action: {
                            showRemoveAlert = true
                        }) {
                            if isRemovingFriend {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Remove Friend")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top, 10)
                        .disabled(isRemovingFriend)
                    }
                    .padding()
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Books Section
                    VStack(alignment: .leading) {
                        Text("\(friend.displayName ?? friend.username ?? "User")'s Books")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView("Loading books...")
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if books.isEmpty {
                            Text("No books in collection yet")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(books) { book in
                                    FriendBookView(book: book)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Friend Profile")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showRemoveAlert) {
                Alert(
                    title: Text("Remove Friend"),
                    message: Text("Are you sure you want to remove \(friend.displayName ?? friend.username ?? "this user") from your friends?"),
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
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .blur(radius: 3)
                            .overlay(Color.black.opacity(0.3))
                    }
                    .frame(height: 160)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(bookColor)
                        .frame(height: 160)
                }
                
                VStack {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                    
                    if book.isCurrentlyReading {
                        Text("Reading")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(4)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)
        }
    }
}
