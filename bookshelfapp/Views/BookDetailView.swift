//
//  BookDetailView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 01.03.25.
//

import SwiftUI

struct BookDetailView: View {
    var repository: Repository
    var userId: String
    var book: Book
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isCurrentlyReading: Bool
    @State private var isLending = false
    @State private var friendName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var bookColor: Color {
        return Color.color(from: book.coverColor)
    }
    
    init(repository: Repository, userId: String, book: Book) {
        self.repository = repository
        self.userId = userId
        self.book = book
        _isCurrentlyReading = State(initialValue: book.isCurrentlyReading)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        if let thumbnailUrl = book.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 120)
                                    .cornerRadius(8)
                            }
                            .frame(width: 80, height: 120)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(bookColor)
                                .frame(width: 80, height: 120)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(book.title)
                                .font(.headline)
                            
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let publishedYear = book.publishedYear {
                                Text("Published: \(publishedYear)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let isbn = book.isbn {
                                Text("ISBN: \(isbn)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if book.isLent {
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text("Lent to: \(book.lentTo ?? "Someone")")
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                                
                                if let lentDate = book.lentDate {
                                    Text("Since: \(lentDate, formatter: dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Toggle("Currently Reading", isOn: $isCurrentlyReading)
                        .onChange(of: isCurrentlyReading) { oldValue, newValue in
                            updateReadingStatus()
                        }
                }
                
                Section {
                    if book.isLent {
                        Button(action: returnBook) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Mark as Returned")
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button(action: { isLending = true }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                Text("Lend This Book")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: deleteBook) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Book")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Book Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $isLending) {
                NavigationView {
                    Form {
                        TextField("Friend's Name", text: $friendName)
                        
                        Button(action: lendBook) {
                            Text("Lend Book")
                        }
                        .disabled(friendName.isEmpty)
                    }
                    .navigationTitle("Lend to a Friend")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isLending = false
                            }
                        }
                    }
                }
            }
            .disabled(isLoading)
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.1)
                            .edgesIgnoringSafeArea(.all)
                        ProgressView()
                    }
                }
            )
        }
    }
    
    private func updateReadingStatus() {
        guard book.id != nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        var updatedBook = book
        updatedBook.isCurrentlyReading = isCurrentlyReading
        
        repository.updateBook(userId: userId, book: updatedBook) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error updating book: \(error.localizedDescription)"
                isCurrentlyReading = book.isCurrentlyReading // Reset to original value
            }
        }
    }
    
    private func lendBook() {
        guard let id = book.id, !friendName.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        isLending = false
        
        repository.lendBook(userId: userId, bookId: id, lentTo: friendName) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error lending book: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func returnBook() {
        guard let id = book.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        repository.returnBook(userId: userId, bookId: id) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error returning book: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func deleteBook() {
        guard let id = book.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        repository.deleteBook(userId: userId, bookId: id) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error deleting book: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
