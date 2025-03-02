//
//  CodeScanner.swift
//  bookshelfapp
//
//  Created by Joshua Rück on 02.03.25.
//

import SwiftUI
import CodeScanner

struct BarcodeScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var scannedISBN: String
    
    var body: some View {
        CodeScannerView(
            codeTypes: [.ean13, .ean8],
            simulatedData: "9780316769488",
            completion: handleScan
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let result):
            let isbn = result.string
            self.scannedISBN = isbn
            self.presentationMode.wrappedValue.dismiss()
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}
