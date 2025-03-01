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
