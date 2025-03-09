//
//  Repository.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 01.03.25.
//

import Foundation
import Firebase
import FirebaseFirestore

struct Book: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var isCurrentlyReading: Bool
    var isLent: Bool = false
    var lentTo: String?
    var lentDate: Date?
    var returnDate: Date?
    var coverColor: String?
    
    var isbn: String?
    var publishedYear: String?
    var thumbnailUrl: String?
}

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var username: String?
    var displayName: String?
    var bio: String?
    var friends: [String]?
    var friendRequests: [String]?
    var createdAt: Date?
    var lastActive: Date?
}

class Repository: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var currentUser: AppUser?
    @Published var friends: [AppUser] = []
    @Published var friendRequests: [AppUser] = []
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var userListenerRegistration: ListenerRegistration?
    private var friendsListenerRegistration: ListenerRegistration?
    private var friendRequestsListenerRegistration: ListenerRegistration?
    
    // MARK: - Book Manipulation
    
    func fetchBooks(for userId: String) {
        isLoading = true
        error = nil
        
        listenerRegistration = db.collection("users").document(userId).collection("books")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = "Failed to fetch books: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                self.books = documents.compactMap { queryDocumentSnapshot -> Book? in
                    let result = Result { try queryDocumentSnapshot.data(as: Book.self) }
                    
                    switch result {
                    case .success(let book):
                        return book
                    case .failure(let error):
                        print("Error decoding book: \(error)")
                        return nil
                    }
                }
                
                self.isLoading = false
            }
    }
    
    func addBook(userId: String, book: Book, completion: @escaping (Error?) -> Void) {
        do {
            let _ = try db.collection("users").document(userId).collection("books").addDocument(from: book)
            completion(nil)
        } catch let error {
            print("Error adding book: \(error)")
            completion(error)
        }
    }
    
    func updateBook(userId: String, book: Book, completion: @escaping (Error?) -> Void) {
        guard let id = book.id else {
            completion(NSError(domain: "Repository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Book ID is missing"]))
            return
        }
        
        do {
            try db.collection("users").document(userId).collection("books").document(id).setData(from: book)
            completion(nil)
        } catch let error {
            print("Error updating book: \(error)")
            completion(error)
        }
    }
    
    func toggleReadingStatus(userId: String, book: Book, completion: @escaping (Error?) -> Void) {
        guard let id = book.id else {
            completion(NSError(domain: "Repository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Book ID is missing"]))
            return
        }
        
        let bookRef = db.collection("users").document(userId).collection("books").document(id)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let bookDocument: DocumentSnapshot
            
            do {
                try bookDocument = transaction.getDocument(bookRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var bookData = bookDocument.data() else {
                let error = NSError(domain: "Repository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Book does not exist"])
                errorPointer?.pointee = error
                return nil
            }
            
            let currentStatus = bookData["isCurrentlyReading"] as? Bool ?? false
            bookData["isCurrentlyReading"] = !currentStatus
            
            transaction.updateData(bookData, forDocument: bookRef)
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error updating reading status: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func deleteBook(userId: String, bookId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).collection("books").document(bookId).delete() { error in
            if let error = error {
                print("Error removing book: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func lendBook(userId: String, bookId: String, lentTo: String, completion: @escaping (Error?) -> Void) {
        let bookRef = db.collection("users").document(userId).collection("books").document(bookId)
        
        bookRef.updateData([
            "isCurrentlyReading": false,
            "isLent": true,
            "lentTo": lentTo,
            "lentDate": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error lending book: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func returnBook(userId: String, bookId: String, completion: @escaping (Error?) -> Void) {
        let bookRef = db.collection("users").document(userId).collection("books").document(bookId)
        
        bookRef.updateData([
            "isLent": false,
            "lentTo": FieldValue.delete(),
            "lentDate": FieldValue.delete(),
            "returnDate": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error returning book: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func cleanUp() {
        listenerRegistration?.remove()
        userListenerRegistration?.remove()
        friendsListenerRegistration?.remove()
    }
    
    // MARK: - User Profile Methods
    
    func createUser(userId: String, email: String, username: String? = nil, completion: @escaping (Error?) -> Void) {
        // Check if username is already taken using the usernames collection
        if let username = username {
            // Check if the username document exists in the usernames collection
            db.collection("usernames").document(username).getDocument { (document, error) in
                if let error = error {
                    print("Error checking username: \(error)")
                    completion(error)
                    return
                }
                
                if let document = document, document.exists {
                    print("Username '\(username)' is already taken")
                    completion(NSError(domain: "Repository", code: 3, userInfo: [NSLocalizedDescriptionKey: "Username already taken"]))
                    return
                }
                
                // Username is available, create user document and username document in a transaction
                self.createUserDocument(userId: userId, email: email, username: username, completion: completion)
            }
        } else {
            // No username provided
            print("No username provided!")
            return
        }
    }
    
    private func createUserDocument(userId: String, email: String, username: String, completion: @escaping (Error?) -> Void) {
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Create the user document data
            let userData: [String: Any] = [
                "email": email,
                "username": username,
                "friends": [],
                "friendRequests": [],
                "createdAt": Timestamp(date: Date()),
                "lastActive": Timestamp(date: Date())
            ]
            
            // Create the username document data
            let usernameData: [String: Any] = [
                "uid": userId,
                "displayName": username,
                "createdAt": Timestamp(date: Date())
            ]
            
            // Set the user document
            let userRef = self.db.collection("users").document(userId)
            transaction.setData(userData, forDocument: userRef)
            
            // Set the username document
            let usernameRef = self.db.collection("usernames").document(username)
            transaction.setData(usernameData, forDocument: usernameRef)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error creating user and username documents: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Successfully created user document for userId: \(userId) with username: \(username)")
                completion(nil)
            }
        }
    }
    
    func fetchCurrentUser(userId: String, completion: ((Error?) -> Void)? = nil) {
        userListenerRegistration = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = "Failed to fetch user data: \(error.localizedDescription)"
                    completion?(error)
                    return
                }
                
                guard let document = documentSnapshot else {
                    let noDocError = NSError(domain: "Repository", code: 1, userInfo: [NSLocalizedDescriptionKey: "User document not found"])
                    self.error = "User document not found"
                    completion?(noDocError)
                    return
                }
                
                let result = Result { try document.data(as: AppUser.self) }
                
                switch result {
                case .success(let user):
                    self.currentUser = user
                    
                    // Create a dispatch group to wait for both operations
                    let group = DispatchGroup()
                    var friendsError: Error?
                    var requestsError: Error?
                    
                    // Fetch friends
                    group.enter()
                    if let friends = user.friends, !friends.isEmpty {
                        self.fetchFriends(friendIds: friends) { error in
                            friendsError = error
                            group.leave()
                        }
                    } else {
                        self.friends = []
                        group.leave()
                    }
                    
                    // Fetch friend requests
                    group.enter()
                    self.fetchFriendRequests(forUserId: userId) { error in
                        requestsError = error
                        group.leave()
                    }
                    
                    // When both operations complete, call the completion handler
                    group.notify(queue: .main) {
                        completion?(friendsError ?? requestsError)
                    }
                    
                case .failure(let error):
                    self.error = "Failed to decode user data: \(error.localizedDescription)"
                    completion?(error)
                }
            }
    }
    
    private func fetchFriendRequests(forUserId: String, completion: @escaping (Error?) -> Void) {
        // Get the current user document to access the friendRequests array
        db.collection("users").document(forUserId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document for friend requests: \(error)")
                self.error = "Failed to fetch friend requests: \(error.localizedDescription)"
                completion(error)
                return
            }
            
            guard let document = document, document.exists, let userData = document.data() else {
                self.friendRequests = []
                completion(nil)
                return
            }
            
            // Get the friend request IDs from the user document
            guard let friendRequestIds = userData["friendRequests"] as? [String], !friendRequestIds.isEmpty else {
                self.friendRequests = []
                completion(nil)
                return
            }
            
            // Fetch the user data for each friend request
            self.db.collection("users")
                .whereField(FieldPath.documentID(), in: friendRequestIds)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error fetching friend request users: \(error)")
                        self.error = "Failed to fetch friend request users: \(error.localizedDescription)"
                        completion(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.friendRequests = []
                        completion(nil)
                        return
                    }
                    
                    let users = documents.compactMap { document -> AppUser? in
                        let result = Result { try document.data(as: AppUser.self) }
                        
                        switch result {
                        case .success(let user):
                            return user
                        case .failure(let error):
                            print("Error decoding user: \(error)")
                            return nil
                        }
                    }
                    
                    self.friendRequests = users
                    completion(nil)
                }
        }
    }
    
    func updateUserProfile(userId: String, username: String?, displayName: String?, bio: String?, completion: @escaping (Error?) -> Void) {
        // Check if username is being changed
        if let newUsername = username, newUsername != currentUser?.username {
            // Check if the new username is already taken
            db.collection("usernames").document(newUsername).getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking username: \(error)")
                    completion(error)
                    return
                }
                
                if let document = document, document.exists {
                    print("Username '\(newUsername)' is already taken")
                    completion(NSError(domain: "Repository", code: 3, userInfo: [NSLocalizedDescriptionKey: "Username already taken"]))
                    return
                }
                
                // Username is available, update profile with username change
                self.performProfileUpdateWithUsernameChange(userId: userId, oldUsername: self.currentUser?.username, newUsername: newUsername, displayName: displayName, bio: bio, completion: completion)
            }
        } else {
            // No username change, update profile directly
            performProfileUpdateWithoutUsernameChange(userId: userId, displayName: displayName, bio: bio, completion: completion)
        }
    }
    
    private func performProfileUpdateWithUsernameChange(userId: String, oldUsername: String?, newUsername: String, displayName: String?, bio: String?, completion: @escaping (Error?) -> Void) {
        // Use a transaction to update the user document and handle username changes
        db.runTransaction({ (transaction, errorPointer) -> Any? in

            // Create the user document update data
            var userData: [String: Any] = [
                "username": newUsername,
                "lastActive": Timestamp(date: Date())
            ]

            // Create the username document data
            var usernameData: [String: Any] = [
                "uid": userId,
                "createdAt": Timestamp(date: Date())
            ]

            if let displayName = displayName {
                userData["displayName"] = displayName
                usernameData["displayName"] = displayName
            }
            
            if let bio = bio {
                userData["bio"] = bio
                usernameData["bio"] = bio
            }
            
            // Update the user document
            let userRef = self.db.collection("users").document(userId)
            transaction.updateData(userData, forDocument: userRef)
            
            // Create the new username document
            let newUsernameRef = self.db.collection("usernames").document(newUsername)
            transaction.setData(usernameData, forDocument: newUsernameRef)
            
            // Delete the old username document if it exists
            if let oldUsername = oldUsername, !oldUsername.isEmpty {
                let oldUsernameRef = self.db.collection("usernames").document(oldUsername)
                transaction.deleteDocument(oldUsernameRef)
            }
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error updating profile with username change: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Successfully updated profile for userId: \(userId) with new username: \(newUsername)")
                completion(nil)
            }
        }
    }
    
    private func performProfileUpdateWithoutUsernameChange(userId: String, displayName: String?, bio: String?, completion: @escaping (Error?) -> Void) {
        // Create the user document update data
        var userData: [String: Any] = [
            "lastActive": Timestamp(date: Date())
        ]
        
        if let displayName = displayName {
            userData["displayName"] = displayName
        }
        
        if let bio = bio {
            userData["bio"] = bio
        }
        
        // Create a batch to ensure atomicity
        let batch = db.batch()
        
        // Update the user document
        let userRef = db.collection("users").document(userId)
        batch.updateData(userData, forDocument: userRef)
        
        // Update the username document if username exists
        if let username = self.currentUser?.username, !username.isEmpty {
            var usernameData: [String: Any] = [
                "uid": userId
            ]
            
            if let displayName = displayName {
                usernameData["displayName"] = displayName
            }
            
            let usernameRef = db.collection("usernames").document(username)
            batch.updateData(usernameData, forDocument: usernameRef)
        }
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error updating profile: \(error)")
                completion(error)
            } else {
                print("Successfully updated profile for userId: \(userId)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Friend Methods
    
    func searchUsers(query: String, currentUserId: String, completion: @escaping ([AppUser], Error?) -> Void) {
        guard !query.isEmpty else {
            completion([], nil)
            return
        }
        
        // Search for usernames that start with the query
        let queryLowercase = query.lowercased()
        let endQuery = queryLowercase + "\u{f8ff}"
        
        // Find matching username documents
        db.collection("usernames")
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: queryLowercase)
            .whereField(FieldPath.documentID(), isLessThanOrEqualTo: endQuery)
            .limit(to: 20)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error searching usernames: \(error.localizedDescription)")
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([], nil)
                    return
                }
                
                // Create AppUser objects directly from username documents
                var users: [AppUser] = []
                
                for document in documents {
                    if let userId = document.data()["uid"] as? String,
                       userId != currentUserId { // Filter out current user
                        
                        // Check if user is already a friend
                        if let currentUser = self.currentUser, 
                           let friends = currentUser.friends, 
                           friends.contains(userId) {
                            continue
                        }
                        
                        // Create a basic AppUser from the username document
                        let username = document.documentID
                        let displayName = document.data()["displayName"] as? String
                        
                        var user = AppUser(id: userId, email: "")
                        user.username = username
                        user.displayName = displayName
                        
                        users.append(user)
                    }
                }
                
                completion(users, nil)
            }
    }
    
    func sendFriendRequest(fromUserId: String, toUserId: String, completion: @escaping (Error?) -> Void) {
        // Get the recipient's user document
        db.collection("users").document(toUserId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting recipient user: \(error)")
                completion(error)
                return
            }
            
            guard let document = document, document.exists else {
                let error = NSError(domain: "Repository", code: 2, userInfo: [NSLocalizedDescriptionKey: "User does not exist"])
                completion(error)
                return
            }
            
            // Check if users are already friends
            if let currentUser = self.currentUser, let friends = currentUser.friends, friends.contains(toUserId) {
                let error = NSError(domain: "Repository", code: 5, userInfo: [NSLocalizedDescriptionKey: "Users are already friends"])
                completion(error)
                return
            }
            
            // Check if request already exists
            if let friendRequests = document.data()?["friendRequests"] as? [String], friendRequests.contains(fromUserId) {
                let error = NSError(domain: "Repository", code: 4, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"])
                completion(error)
                return
            }
            
            // Add the friend request to the recipient's friendRequests array
            self.db.collection("users").document(toUserId).updateData([
                "friendRequests": FieldValue.arrayUnion([fromUserId])
            ]) { error in
                if let error = error {
                    print("Error sending friend request: \(error)")
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func acceptFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Error?) -> Void) {
        // First, check if the friend request exists
        db.collection("users").document(currentUserId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting current user document: \(error)")
                completion(error)
                return
            }
            
            guard let document = document, document.exists else {
                print("Current user document not found")
                completion(NSError(domain: "Repository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Current user does not exist"]))
                return
            }
            
            // Get the current user's friend requests
            guard let userData = document.data() else {
                print("Current user data is nil")
                completion(NSError(domain: "Repository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"]))
                return
            }
            
            let friendRequests = userData["friendRequests"] as? [String] ?? []
            print("Current friend requests: \(friendRequests)")
            
            // Check if the friend request exists
            if !friendRequests.contains(friendId) {
                print("Friend request not found in array. Looking for \(friendId) in \(friendRequests)")
                completion(NSError(domain: "Repository", code: 6, userInfo: [NSLocalizedDescriptionKey: "Friend request not found"]))
                return
            }
            
            // Now perform the updates in a batch to ensure atomicity
            let batch = self.db.batch()
            
            // 1. Remove friend from current user's friendRequests array and add to friends array
            let currentUserRef = self.db.collection("users").document(currentUserId)
            batch.updateData([
                "friendRequests": FieldValue.arrayRemove([friendId]),
                "friends": FieldValue.arrayUnion([friendId])
            ], forDocument: currentUserRef)
            
            // 2. Add current user to friend's friends array
            let friendUserRef = self.db.collection("users").document(friendId)
            batch.updateData([
                "friends": FieldValue.arrayUnion([currentUserId])
            ], forDocument: friendUserRef)
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error accepting friend request: \(error)")
                    completion(error)
                } else {
                    print("Successfully accepted friend request from \(friendId)")
                    
                    // Refresh data from server
                    self.fetchCurrentUser(userId: currentUserId) { _ in
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func rejectFriendRequest(currentUserId: String, friendId: String, completion: @escaping (Error?) -> Void) {
        // Get the current user document
        let currentUserRef = db.collection("users").document(currentUserId)
        
        // Update the document to remove the friend request
        currentUserRef.updateData([
            "friendRequests": FieldValue.arrayRemove([friendId])
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error rejecting friend request: \(error)")
                completion(error)
            } else {
                // Refresh data from server
                self.fetchCurrentUser(userId: currentUserId) { _ in
                    completion(nil)
                }
            }
        }
    }
    
    func removeFriend(currentUserId: String, friendId: String, completion: @escaping (Error?) -> Void) {
        let currentUserRef = db.collection("users").document(currentUserId)
        let friendUserRef = db.collection("users").document(friendId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let currentUserDocument: DocumentSnapshot
            let friendUserDocument: DocumentSnapshot
            
            do {
                try currentUserDocument = transaction.getDocument(currentUserRef)
                try friendUserDocument = transaction.getDocument(friendUserRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var currentUserData = currentUserDocument.data(),
                  var friendUserData = friendUserDocument.data() else {
                let error = NSError(domain: "Repository", code: 2, userInfo: [NSLocalizedDescriptionKey: "User does not exist"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update current user's data
            var currentUserFriends = currentUserData["friends"] as? [String] ?? []
            
            if let index = currentUserFriends.firstIndex(of: friendId) {
                currentUserFriends.remove(at: index)
            } else {
                let error = NSError(domain: "Repository", code: 7, userInfo: [NSLocalizedDescriptionKey: "Friend not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            currentUserData["friends"] = currentUserFriends
            
            // Update friend's data
            var friendUserFriends = friendUserData["friends"] as? [String] ?? []
            
            if let index = friendUserFriends.firstIndex(of: currentUserId) {
                friendUserFriends.remove(at: index)
            }
            
            friendUserData["friends"] = friendUserFriends
            
            transaction.updateData(currentUserData, forDocument: currentUserRef)
            transaction.updateData(friendUserData, forDocument: friendUserRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error removing friend: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    private func fetchFriends(friendIds: [String], completion: @escaping (Error?) -> Void) {
        db.collection("users")
            .whereField(FieldPath.documentID(), in: friendIds)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching friends: \(error)")
                    self.error = "Failed to fetch friends: \(error.localizedDescription)"
                    completion(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.friends = []
                    completion(nil)
                    return
                }
                
                self.friends = documents.compactMap { queryDocumentSnapshot -> AppUser? in
                    let result = Result { try queryDocumentSnapshot.data(as: AppUser.self) }
                    
                    switch result {
                    case .success(let user):
                        return user
                    case .failure(let error):
                        print("Error decoding friend: \(error)")
                        return nil
                    }
                }
                
                completion(nil)
            }
    }
    
    func fetchFriendBooks(friendId: String, completion: @escaping ([Book], Error?) -> Void) {
        db.collection("users").document(friendId).collection("books")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching friend's books: \(error)")
                    completion([], error)
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let books = documents.compactMap { queryDocumentSnapshot -> Book? in
                    let result = Result { try queryDocumentSnapshot.data(as: Book.self) }
                    
                    switch result {
                    case .success(let book):
                        return book
                    case .failure(let error):
                        print("Error decoding book: \(error)")
                        return nil
                    }
                }
                
                completion(books, nil)
            }
    }
}
