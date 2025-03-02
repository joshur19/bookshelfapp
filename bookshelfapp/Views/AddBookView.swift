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
    @State private var publishedYear = ""
    @State private var isCurrentlyReading = false
    @State private var selectedColor = "blue"
    @State private var thumbnailUrl: String? = nil
    @State private var isbn: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var selectedSwiftUIColor: Color {
        colors.first { $0.name.lowercased() == selectedColor.lowercased() }?.color ?? Color.blue
    }
    
    @State private var scannedISBN: String = ""
    @State private var showingScanner = false
    @State private var isSearchingBook = false
    @State private var bookThumbnail: UIImage? = nil
    
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
                Section(header: Text("Add Method")) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Scan Book Barcode")
                        }
                    }
                    .sheet(isPresented: $showingScanner) {
                        BarcodeScannerView(scannedISBN: $scannedISBN)
                            .onDisappear {
                                if !scannedISBN.isEmpty {
                                    isbn = scannedISBN
                                    searchBookByISBN()
                                }
                            }
                    }
                }
                
                if isSearchingBook {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Searching book details...")
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("Book Cover")) {
                    HStack {
                        Spacer()
                        if let image = bookThumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 160)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedSwiftUIColor)
                                .frame(height: 160)
                                .frame(width: 120)
                                .overlay(
                                    Text(title.isEmpty ? "Cover" : String(title.prefix(1)))
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                )
                                .shadow(radius: 2)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Book Details")) {
                    TextField("Book Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Published Year", text: $publishedYear)
                        .keyboardType(.numberPad)
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                    Toggle("Currently Reading", isOn: $isCurrentlyReading)
                }
                
                // Only show color picker if no thumbnail is available
                if bookThumbnail == nil {
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
        
        // Modify the thumbnailUrl to use HTTPS if it's HTTP
        var secureThumbnailUrl = thumbnailUrl
        if let url = thumbnailUrl, url.lowercased().hasPrefix("http://") {
            secureThumbnailUrl = url.replacingOccurrences(of: "http://", with: "https://")
        }
        
        let newBook = Book(
            title: title,
            author: author,
            isCurrentlyReading: isCurrentlyReading,
            coverColor: selectedColor,
            isbn: isbn.isEmpty ? nil : isbn,
            publishedYear: publishedYear.isEmpty ? nil : publishedYear,
            thumbnailUrl: secureThumbnailUrl
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
    
    private func searchBookByISBN() {
        isSearchingBook = true
        errorMessage = nil
        
        let bookService = BookService()
        bookService.fetchBookDetails(isbn: scannedISBN) { result in
            DispatchQueue.main.async {
                isSearchingBook = false
                
                switch result {
                case .success(let bookDetails):
                    self.title = bookDetails.title
                    self.author = bookDetails.author
                    self.publishedYear = bookDetails.publishedYear
                    self.thumbnailUrl = bookDetails.thumbnailUrl
                    
                    if let thumbnailUrlString = bookDetails.thumbnailUrl,
                       let thumbnailUrl = URL(string: thumbnailUrlString) {
                        downloadThumbnail(from: thumbnailUrl)
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Could not find book: \(error.localizedDescription)"
                }
            }
        }
    }

    private func downloadThumbnail(from url: URL) {
        var secureURL = url
        
        if url.scheme == "http" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "https"
            
            if let newURL = components?.url {
                secureURL = newURL
            }
        }
        
        URLSession.shared.dataTask(with: secureURL) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data) {
                    self.bookThumbnail = image
                }
            }
        }.resume()
    }
}
