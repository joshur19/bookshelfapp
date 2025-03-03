//
//  CachedAsyncImage.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 03.03.25.
//

import SwiftUI
import Foundation

struct CachedAsyncImage<Content: View>: View {
    private let url: URL
    private let content: (Image) -> Content
    @State private var cachedImage: UIImage? = nil
    @State private var isLoading = true
    
    init(url: URL, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                content(Image(uiImage: cachedImage))
            } else if isLoading {
                ProgressView()
            } else {
                // Fallback view when image fails to load
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        
        // Check if image exists in cache
        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            self.cachedImage = image
            self.isLoading = false
            return
        }
        
        // Otherwise download it
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let response = response, error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Store in cache
            let cachedData = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedData, for: URLRequest(url: url))
            
            DispatchQueue.main.async {
                self.cachedImage = image
                self.isLoading = false
            }
        }.resume()
    }
}
