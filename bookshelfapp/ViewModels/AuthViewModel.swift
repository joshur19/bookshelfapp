//
//  AuthViewModel.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 22.02.25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var user: FirebaseAuth.User? = nil
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
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                let errorMessage = "Invalid or unregistered credentials. Please try again."
                print("Login error: \(error.localizedDescription)")
                completion(errorMessage)
                return
            }
            
            print("Login successful for email: \(email)")
            self.isLoggedIn = true
            self.user = Auth.auth().currentUser
            completion(nil)
        }
    }
    
    func register(email: String, password: String, completion: @escaping (String?) -> Void) {
        self.isRegistering = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isRegistering = false
                print("Registration error: \(error.localizedDescription)")
                completion(error.localizedDescription)
                return
            }
            
            guard let user = result?.user else {
                self.isRegistering = false
                print("Registration error: User is nil")
                completion("Failed to create user account")
                return
            }
            
            print("Registration successful for email: \(email)")
            self.isRegistering = true
            self.user = user
            
            completion(nil)
        }
    }
    
    func completeRegistration() {
        do {
            // Sign out manually after registering, counteracting Firebase's built-in createUser() behaviour
            try Auth.auth().signOut()
            self.isRegistering = false
            self.user = nil
            self.isLoggedIn = false
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
    
    func deleteAuthAccount(user: FirebaseAuth.User, completion: @escaping () -> Void) {
        user.delete { error in
            if let error = error {
                print("Error deleting user account: \(error.localizedDescription)")
            } else {
                print("User account deleted due to Firestore setup failure")
            }
            self.isRegistering = false
            self.user = nil
            self.isLoggedIn = false
            completion()
        }
    }
}
