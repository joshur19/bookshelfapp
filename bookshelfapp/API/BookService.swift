//
//  BookService.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 02.03.25.
//

import Foundation

class BookService {
    private let apiKey = Config().apiKey
    
    func fetchBookDetails(isbn: String, completion: @escaping (Result<BookDetails, Error>) -> Void) {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "BookService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "BookService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse Google Books API response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstBook = items.first,
                   let volumeInfo = firstBook["volumeInfo"] as? [String: Any] {
                    
                    // Extract only relevant book information
                    let title = volumeInfo["title"] as? String ?? "Unknown Title"
                    
                    let authorsArray = volumeInfo["authors"] as? [String]
                    let author = authorsArray?.joined(separator: ", ") ?? "Unknown Author"
                    
                    let publishedDate = volumeInfo["publishedDate"] as? String ?? ""
                    let publishedYear = publishedDate.prefix(4)
                    
                    var thumbnailUrl: String? = nil
                    if let imageLinks = volumeInfo["imageLinks"] as? [String: Any] {
                        thumbnailUrl = imageLinks["thumbnail"] as? String
                    }
                    
                    // Create book details object
                    let bookDetails = BookDetails(
                        title: title,
                        author: author,
                        publishedYear: String(publishedYear),
                        thumbnailUrl: thumbnailUrl
                    )
                    
                    completion(.success(bookDetails))
                } else {
                    completion(.failure(NSError(domain: "BookService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No books found for this ISBN"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
}

// Simplified struct to hold only relevant book details
struct BookDetails {
    let title: String
    let author: String
    let publishedYear: String
    let thumbnailUrl: String?
    
    // Convert these details to book model
    func toBook() -> Book {
        return Book(
            id: nil,
            title: title,
            author: author,
            isCurrentlyReading: false,
            isLent: false,
            lentTo: nil,
            lentDate: nil,
            returnDate: nil,
            coverColor: "blue", // Default color or you could determine this from the thumbnail
            
            publishedYear: publishedYear,
            thumbnailUrl: thumbnailUrl
        )
    }
}

// Models for decoding Google Books API response
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let volumeInfo: GoogleBookVolumeInfo?
}

struct GoogleBookVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let publishedDate: String?
    let imageLinks: GoogleBookImageLinks?
}

struct GoogleBookImageLinks: Codable {
    let thumbnail: String?
}
