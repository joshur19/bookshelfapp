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
        
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 100 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, directory: nil)
        URLCache.shared = cache // Configure URLCache with 50MB disk cache and 10MB memory cache
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn && !authViewModel.isRegistering {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(repository)
                    .onDisappear {
                        repository.cleanUp()
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(repository)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var repository: Repository
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BookshelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical")
                }
                .tag(0)
            
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}
