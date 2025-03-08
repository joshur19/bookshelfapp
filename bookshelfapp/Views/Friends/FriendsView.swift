//
//  FriendsView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 04.03.25.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var showSearchSheet = false
    @State private var selectedFriend: AppUser? = nil
    @State private var friendBooks: [Book] = []
    @State private var isLoadingBooks = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if repository.friends.isEmpty && repository.friendRequests.isEmpty {
                    EmptyFriendsView()
                } else {
                    List {
                        if !repository.friendRequests.isEmpty {
                            Section(header: Text("Friend Requests")) {
                                ForEach(repository.friendRequests) { user in
                                    FriendRequestRow(user: user)
                                }
                            }
                        }
                        
                        if !repository.friends.isEmpty {
                            Section(header: Text("Friends")) {
                                ForEach(repository.friends) { friend in
                                    FriendRow(friend: friend)
                                        .onTapGesture {
                                            selectedFriend = friend
                                            loadFriendBooks(friendId: friend.id ?? "")
                                        }
                                }
                            }
                        }
                    }
                }
                
                Button(action: {
                    showSearchSheet = true
                }) {
                    Label("Find Friends", systemImage: "person.badge.plus")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Friends")
            .sheet(isPresented: $showSearchSheet) {
                SearchUsersView()
            }
            .sheet(item: $selectedFriend) { friend in
                FriendProfileView(friend: friend, books: friendBooks, isLoading: isLoadingBooks)
            }
        }
    }
    
    private func loadFriendBooks(friendId: String) {
        isLoadingBooks = true
        friendBooks = []
        errorMessage = nil
        
        repository.fetchFriendBooks(friendId: friendId) { books, error in
            isLoadingBooks = false
            
            if let error = error {
                errorMessage = "Failed to load books: \(error.localizedDescription)"
            } else {
                friendBooks = books
            }
        }
    }
}

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Connect with friends to see their bookshelves and share your reading journey.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 100)
        .padding(.horizontal)
    }
}

struct FriendRow: View {
    var friend: AppUser
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(friend.displayName ?? friend.username ?? "User")
                    .font(.headline)
                
                if let username = friend.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct FriendRequestRow: View {
    var user: AppUser
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    @State private var isAccepting = false
    @State private var isRejecting = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(user.displayName ?? user.username ?? "User")
                        .font(.headline)
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if isAccepting || isRejecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    HStack {
                        Button(action: {
                            acceptFriendRequest()
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        
                        Button(action: {
                            rejectFriendRequest()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func acceptFriendRequest() {
        guard let currentUserId = authViewModel.user?.uid, let friendId = user.id else {
            errorMessage = "Unable to accept request"
            return
        }
        
        print("Accepting friend request from \(friendId) to \(currentUserId)")
        isAccepting = true
        errorMessage = nil
        
        repository.acceptFriendRequest(currentUserId: currentUserId, friendId: friendId) { error in
            isAccepting = false
            
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
                errorMessage = "Failed to accept: \(error.localizedDescription)"
                
                // If it's a "Friend request not found" error, we might need to refresh the UI
                if let nsError = error as NSError?, nsError.domain == "Repository" && nsError.code == 6 {
                    // Force refresh the current user data
                    if let userId = authViewModel.user?.uid {
                        repository.fetchCurrentUser(userId: userId)
                    }
                }
            }
        }
    }
    
    private func rejectFriendRequest() {
        guard let currentUserId = authViewModel.user?.uid, let friendId = user.id else {
            errorMessage = "Unable to reject request"
            return
        }
        
        print("Rejecting friend request from \(friendId) to \(currentUserId)")
        isRejecting = true
        errorMessage = nil
        
        repository.rejectFriendRequest(currentUserId: currentUserId, friendId: friendId) { error in
            isRejecting = false
            
            if let error = error {
                print("Error rejecting friend request: \(error.localizedDescription)")
                errorMessage = "Failed to reject: \(error.localizedDescription)"
            }
        }
    }
}


#Preview {
    FriendsView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
} 
