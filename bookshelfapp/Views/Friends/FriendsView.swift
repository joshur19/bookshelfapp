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
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                if repository.friends.isEmpty && repository.friendRequests.isEmpty {
                    EmptyFriendsView()
                } else {
                    List {
                        if !repository.friendRequests.isEmpty {
                            Section(header: Text("Friend Requests")) {
                                ForEach(repository.friendRequests.indices, id: \.self) { index in
                                    let user = repository.friendRequests[index]
                                    FriendRequestRow(user: user, onRequestHandled: {
                                        refreshFriends()
                                    })
                                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                        
                        if !repository.friends.isEmpty {
                            Section(header: Text("Friend List")) {
                                ForEach(repository.friends.indices, id: \.self) { index in
                                    let friend = repository.friends[index]
                                    FriendRow(friend: friend)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedFriend = friend
                                            loadFriendBooks(friendId: friend.id ?? "")
                                        }
                                }
                            }
                        }
                    }
                    .id(refreshTrigger)
                    .refreshable {
                        refreshFriends()
                    }
                    .listStyle(InsetGroupedListStyle())
                    .background(Color(.systemGroupedBackground))
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
                }
                .padding(.bottom)
                .contentShape(Rectangle())
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Friends")
                        .font(.title)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSearchSheet) {
                SearchUsersView()
            }
            .sheet(item: $selectedFriend) { friend in
                FriendProfileView(friend: friend, books: friendBooks, isLoading: isLoadingBooks)
            }
        }
        .onAppear {
            refreshFriends()
        }
    }
    
    private func refreshFriends() {
        if let userId = authViewModel.user?.uid {
            repository.fetchCurrentUser(userId: userId) { _ in
                DispatchQueue.main.async {
                    refreshTrigger.toggle()
                }
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
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            Text("No Friends Yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Connect with friends to see their bookshelves and share your reading journey.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            
            Spacer()
            
            // Add a spacer with the height of the button plus its padding
            // to ensure proper vertical centering
            Spacer()
                .frame(height: 80)
        }
    }
}

struct FriendRow: View {
    var friend: AppUser
    
    var displayName: String {
        if let name = friend.displayName, !name.isEmpty {
            return name
        }
        return friend.username ?? "User"
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(displayName)
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
        .contentShape(Rectangle())
    }
}

struct FriendRequestRow: View {
    var user: AppUser
    var onRequestHandled: () -> Void
    
    var displayName: String {
        if let name = user.displayName, !name.isEmpty {
            return name
        }
        return user.username ?? "User"
    }
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    @State private var isAccepting = false
    @State private var isRejecting = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .layoutPriority(0)
                
                Spacer(minLength: 4)
                
                if isAccepting || isRejecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 100)
                } else {
                    HStack(spacing: 8) {
                        acceptButton
                        declineButton
                    }
                    .layoutPriority(1)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var acceptButton: some View {
        Button(action: {
            acceptFriendRequest()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                Text("Accept")
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .frame(width: 90)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(ScaleButtonStyle())
        .contentShape(Rectangle())
    }
    
    private var declineButton: some View {
        Button(action: {
            rejectFriendRequest()
        }) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                Text("Decline")
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .frame(width: 90)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(ScaleButtonStyle())
        .contentShape(Rectangle())
    }
    
    private func acceptFriendRequest() {
        guard let currentUserId = authViewModel.user?.uid, let friendId = user.id else {
            errorMessage = "Unable to accept request"
            return
        }
        
        print("Starting friend request acceptance from \(friendId) to \(currentUserId)")
        isAccepting = true
        isRejecting = true // Disable both buttons during operation
        errorMessage = nil
        
        repository.acceptFriendRequest(currentUserId: currentUserId, friendId: friendId) { error in
            isAccepting = false
            isRejecting = false // Re-enable both buttons
            
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
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onRequestHandled()
                }
            }
        }
    }
    
    private func rejectFriendRequest() {
        guard let currentUserId = authViewModel.user?.uid, let friendId = user.id else {
            errorMessage = "Unable to reject request"
            return
        }
        
        print("Starting friend request rejection from \(friendId) to \(currentUserId)")
        isRejecting = true
        isAccepting = true // Disable both buttons during operation
        errorMessage = nil
        
        repository.rejectFriendRequest(currentUserId: currentUserId, friendId: friendId) { error in
            isRejecting = false
            isAccepting = false // Re-enable both buttons
            
            if let error = error {
                print("Error rejecting friend request: \(error.localizedDescription)")
                errorMessage = "Failed to reject: \(error.localizedDescription)"
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onRequestHandled()
                }
            }
        }
    }
}


#Preview {
    FriendsView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
} 
