//
//  AddBookView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 01.03.25.
//

import SwiftUI

struct AddBookView: View {
    var repository: Repository
    var userId: String
    
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var author = ""
    @State private var isCurrentlyReading = false
    @State private var selectedColor = "blue"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let colors = [
        (name: "Red", color: Color.red),
        (name: "Blue", color: Color.blue),
        (name: "Green", color: Color.green),
        (name: "Orange", color: Color.orange),
        (name: "Purple", color: Color.purple),
        (name: "Yellow", color: Color.yellow)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Book Title", text: $title)
                    TextField("Author", text: $author)
                    Toggle("Currently Reading", isOn: $isCurrentlyReading)
                }
                
                Section(header: Text("Cover Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.name) { colorOption in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorOption.color)
                                    .frame(width: 60, height: 80)
                                    .overlay(
                                        Group {
                                            if selectedColor.lowercased() == colorOption.name.lowercased() {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        selectedColor = colorOption.name.lowercased()
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: addBook) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Add Book")
                        }
                    }
                    .disabled(title.isEmpty || author.isEmpty || isLoading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Add a Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .disabled(isLoading)
        }
    }
    
    private func addBook() {
        guard !title.isEmpty && !author.isEmpty && !userId.isEmpty else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let newBook = Book(
            title: title,
            author: author,
            isCurrentlyReading: isCurrentlyReading,
            coverColor: selectedColor
        )
        
        repository.addBook(userId: userId, book: newBook) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error adding book: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
