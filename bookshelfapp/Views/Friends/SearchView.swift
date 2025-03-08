//
//  SearchView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 08.03.25.
//

import SwiftUI

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
