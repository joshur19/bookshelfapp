//
//  AuthViewModel.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 22.02.25.
//

import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var user: User? = nil
    @Published var isRegistering: Bool = false
    
    private var authListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen to changes in authentication
        self.authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isLoggedIn = user != nil
        }
    }
    
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                let errorMessage = "Invalid or unregistered credentials. Please try again."
                completion(errorMessage)
                return
            }
            
            completion(nil)
        }
    }
    
    func register(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.isRegistering = false
                completion(error.localizedDescription)
                return
            }
            
            self.isRegistering = true
            completion(nil)
        }
    }
    
    func completeRegistration() {
        do {
            // Sign out manually after registering, counter-acting Firebase's built-in createUser() behaviour
            try Auth.auth().signOut()
            self.isRegistering = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isLoggedIn = false
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
    
}
