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

struct SearchUsersView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var searchQuery = ""
    @State private var searchResults: [AppUser] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                SearchBar(text: $searchQuery, placeholder: "Search by username", onCommit: performSearch)
                    .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(searchResults) { user in
                            SearchResultRow(user: user)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Find Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        if let currentUserId = authViewModel.user?.uid {
            repository.searchUsers(query: searchQuery, currentUserId: currentUserId) { users, error in
                isSearching = false
                
                if let error = error {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    searchResults = []
                } else {
                    searchResults = users
                }
            }
        } else {
            isSearching = false
            errorMessage = "You must be logged in to search for users"
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text, onCommit: onCommit)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: text) { _ in
                    onCommit()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onCommit()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SearchResultRow: View {
    var user: AppUser
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var isSendingRequest = false
    @State private var requestSent = false
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
                
                if requestSent {
                    Text("Request Sent")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if isSendingRequest {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: {
                        sendFriendRequest()
                    }) {
                        Text("Add Friend")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
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
    
    private func sendFriendRequest() {
        guard let currentUserId = authViewModel.user?.uid, let friendId = user.id else {
            errorMessage = "Unable to send request"
            return
        }
        
        isSendingRequest = true
        errorMessage = nil
        
        repository.sendFriendRequest(fromUserId: currentUserId, toUserId: friendId) { error in
            isSendingRequest = false
            
            if let error = error {
                if let nsError = error as NSError?, nsError.domain == "Repository" && nsError.code == 5 {
                    errorMessage = "You are already friends with this user"
                } else if let nsError = error as NSError?, nsError.domain == "Repository" && nsError.code == 4 {
                    errorMessage = "Friend request already sent"
                } else {
                    errorMessage = "Failed to send request: \(error.localizedDescription)"
                }
            } else {
                requestSent = true
            }
        }
    }
}

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
                            .blur(radius: 3) // Add slight blur
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

#Preview {
    FriendsView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
} 
