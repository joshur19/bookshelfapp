//
//  bookshelfappApp.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 22.02.25.
//

import SwiftUI
import Firebase

@main
struct bookshelfappApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var repository = Repository()
    
    init() {
        FirebaseApp.configure()
        
        // Configure URLCache with 50MB disk cache and 10MB memory cache
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 100 * 1024 * 1024 // 100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, directory: nil)
        URLCache.shared = cache
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn && !authViewModel.isRegistering {
                BookshelfView()
                    .environmentObject(authViewModel)
                    .environmentObject(repository)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(repository)
            }
        }
    }
}
