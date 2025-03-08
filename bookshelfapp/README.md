# 📚 BookshelfApp

A sleek and simple iOS application for book lovers to manage their personal library, track reading progress, and connect with friends.


## ✨ Features at a Glance

- **📚 Personal Bookshelf**: Add, organize, and manage your book collection
- **🔍 Book Search**: Add books to your collection by scanning barcodes
- **👥 Social Features**: Connect with friends and explore their bookshelves
- **📖 Reading Tracker**: Track books you're currently reading
- **📱 Lending System**: Keep track of books you've lent to friends
- **🎨 Modern SwiftUI Interface**: Clean, intuitive UI built with SwiftUI

## 📌 Book Organization

Digitally catalog your books by scanning barcodes (ISBN lookup) or adding them manually. Organize with three intuitive shelves:  

- **"All Books" Shelf**: Your complete digital collection
- **"Currently Reading" Shelf**: Quick access to books in progress
- **"Lent Books" Shelf**: The books you've marked as "lent" to friends

## 👥 Social Features

- **Add Friends**: See their bookshelves and current reads
- **Loan Tracking**: Mark books as lent to friends, friends can see which are unavailable
- **Custom Profiles**: Customize your user profile with a display name and bio

## 🔧 Technical Stack

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Modern declarative UI framework |
| **Firebase Auth** | Secure user authentication |
| **Firestore** | Cloud database for book and user data |
| **Google Books API** | Book information retrieval |
| **CodeScanner** | Barcode scanning functionality |

## 📦 Core Components

- **Authentication**: Secure user login and registration via Firebase Auth
- **Book Management**: CRUD operations for your book collection (Firestore)
- **Friend System**: Connect with other users (managed via Firestore)
- **Profile Management**: Customize your user profile
- **Book Search API**: Integration with Google Books API

## 🚀 Getting Started

1. Clone the repository
2. Install dependencies (Firebase Authentication, Firestore, [CodeScanner library](https://github.com/twostraws/CodeScanner.git))
3. Set up your own Firebase project and add your `GoogleService-Info.plist`
4. Connect a Google Books API key and add it to a Config.swift file in the project
5. Build and run in Xcode

## 📸 Screenshots

[Screenshots will be added here]

## 🔮 Future Enhancements

- [ ] Directly associate loaned books with people from your friends list
- [ ] More stable and reliable implementation of backend behind friends system
- [ ] Some kind of monetization (caps on monthly ISBN scans, advanced categorization, etc.)
- [ ] Rate/review books you've read so friends can see what you like
- [ ] Create wishlists and share these with friends
- [ ] More customizability in categorizing your library, including marking books as "private"
- [ ] Publish app officially to App Store

---

Built with ❤️ for book lovers everywhere