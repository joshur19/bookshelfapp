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
}

class Repository: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func createUserDocument(userId: String, email: String, completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "lastActive": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                print("Error creating user document: \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
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
    }
}
