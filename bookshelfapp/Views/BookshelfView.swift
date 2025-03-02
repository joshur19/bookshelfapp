//
//  BookshelfView.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 22.02.25.
//

import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    
    @State private var selectedShelf: String = "Currently Reading"
    @State private var showAddBookSheet = false
    @State private var showLendBookSheet = false
    @State private var selectedBook: Book?
    
    var filteredBooks: [Book] {
        switch selectedShelf {
        case "Currently Reading":
            return repository.books.filter { $0.isCurrentlyReading }
        case "All Books":
            return repository.books
        case "Lent Books":
            return repository.books.filter { $0.isLent }
        default:
            return repository.books
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Shelf", selection: $selectedShelf) {
                    Text("Currently Reading").tag("Currently Reading")
                    Text("All Books").tag("All Books")
                    Text("Lent Books").tag("Lent Books")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if repository.isLoading {
                    ProgressView("Loading books...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = repository.error {
                    VStack {
                        Text("Error loading books")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button("Try Again") {
                            if let userId = authViewModel.user?.uid {
                                repository.fetchBooks(for: userId)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top)
                    }
                    .padding()
                } else if filteredBooks.isEmpty {
                    VStack {
                        Text(selectedShelf == "Lent Books" ? "No lent books" : "No books found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(selectedShelf == "Lent Books" ? "Books you lend to friends will appear here" : "Add some books to your collection")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        if selectedShelf != "Lent Books" {
                            Button(action: {
                                showAddBookSheet.toggle()
                            }) {
                                Label("Add your first book", systemImage: "plus")
                                    .padding()
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredBooks) { book in
                                BookView(book: book)
                                    .onTapGesture {
                                        selectedBook = book
                                        showLendBookSheet = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                Button(action: {
                    showAddBookSheet.toggle()
                }) {
                    Label("Add a Book", systemImage: "plus")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Bookshelf")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showAddBookSheet) {
                AddBookView(repository: repository, userId: authViewModel.user?.uid ?? "")
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(repository: repository, userId: authViewModel.user?.uid ?? "", book: book)
            }
            .onAppear {
                if let userId = authViewModel.user?.uid {
                    withAnimation(nil) {
                        repository.fetchBooks(for: userId)
                    }
                }
            }
            .onDisappear {
                repository.cleanUp()
            }
            .animation(nil, value: repository.isLoading)
        }
    }
}

// Individual grid items
struct BookView: View {
    var book: Book
    
    // Convert stored color string to Color
    var bookColor: Color {
        if let colorName = book.coverColor, let color = colorFromString(colorName) {
            return color
        } else {
            return .gray
        }
    }
    
    // Ensure the thumbnail URL is always HTTPS
    var secureThumbnailUrl: URL? {
        guard let thumbnailUrl = book.thumbnailUrl,
              var urlComponents = URLComponents(string: thumbnailUrl) else {
            return nil
        }
        
        if urlComponents.scheme == "http" {
            urlComponents.scheme = "https"
        }
        
        return urlComponents.url
    }
    
    func colorFromString(_ colorName: String) -> Color? {
        switch colorName {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return nil
        }
    }
    
    var body: some View {
        VStack {
            if let url = secureThumbnailUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        // Fallback to color rectangle if image fails to load
                        RoundedRectangle(cornerRadius: 8)
                            .fill(bookColor)
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Text(book.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 5)
                                    
                                    Text(book.author)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.top, 2)
                                    
                                    if book.isLent {
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white)
                                            Text(book.lentTo ?? "Someone")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        }
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .padding(.top, 4)
                                    } else if book.isCurrentlyReading {
                                        Text("Reading")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.green.opacity(0.7))
                                            .cornerRadius(4)
                                            .padding(.top, 4)
                                    }
                                }
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(bookColor)
                            .frame(height: 160)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(bookColor)
                    .frame(height: 160)
                    .overlay(
                        VStack {
                            Text(book.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 5)
                            
                            Text(book.author)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 2)
                            
                            if book.isLent {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                    Text(book.lentTo ?? "Someone")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                                .padding(4)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(4)
                                .padding(.top, 4)
                            } else if book.isCurrentlyReading {
                                Text("Reading")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.green.opacity(0.7))
                                    .cornerRadius(4)
                                    .padding(.top, 4)
                            }
                        }
                    )
                    .shadow(radius: 2)
            }
            
            // Rest of your BookView
        }
    }
}

#Preview{
    BookshelfView()
        .environmentObject(AuthViewModel())
        .environmentObject(Repository())
}
