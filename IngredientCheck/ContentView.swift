//
//  ContentView.swift
//  IngredientCheck
//
//  Created by Fatih Catpinar on 3/28/26.
//

import SwiftUI
import VisionKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    VStack(spacing: 10) {
                        Text("Ingredient Check")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Scan food barcodes and quickly view product details and ingredients.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    NavigationLink(destination: ScanView()) {
                        Text("Scan Product")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    Text("Product data provided by Open Food Facts")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ScanView: View {
    @State private var scannedCode: String = ""
    @State private var product: Product? = nil
    @State private var isLoading: Bool = false
    @State private var lastFetchedCode: String = ""
    @State private var hasScanned: Bool = false
    @State private var errorMessage: String = ""

    let productService = ProductService()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if !hasScanned {
                        scannerSection
                    } else {
                        resultSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scannedCode) { newCode in
            fetchProductIfNeeded(barcode: newCode)
        }
    }

    var scannerSection: some View {
        VStack(spacing: 16) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                VStack(spacing: 16) {
                    ScannerView(scannedCode: $scannedCode)
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("Point the camera at a product barcode")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(20)
            } else {
                Text("Scanner is not available on this device.")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
            }
        }
    }

    var resultSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Scanned Barcode")
                    .font(.headline)

                Text(scannedCode)
                    .font(.body)
                    .foregroundColor(.secondary)

                if isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading product...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                if let product = product, !isLoading {
                    if let imageUrl = product.imageUrl,
                       let url = URL(string: imageUrl),
                       !imageUrl.isEmpty {
                        HStack {
                            Spacer()
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 140)
                            Spacer()
                        }
                    }

                    infoRow(title: "Brand", value: product.brands)
                    infoRow(title: "Product Name", value: product.productName)
                    infoRow(title: "Ingredients", value: product.ingredientsText)
                }

                if !errorMessage.isEmpty && !isLoading {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)

            Button(action: resetScanner) {
                Text("Scan Another")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
    }

    @ViewBuilder
    func infoRow(title: String, value: String?) -> some View {
        if let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    func fetchProductIfNeeded(barcode: String) {
        guard !barcode.isEmpty else { return }
        guard barcode != lastFetchedCode else { return }

        lastFetchedCode = barcode
        hasScanned = true
        isLoading = true
        product = nil
        errorMessage = ""

        productService.fetchProduct(barcode: barcode) { result in
            isLoading = false

            switch result {
            case .success(let fetchedProduct):
                product = fetchedProduct

            case .notFound:
                errorMessage = "Product not found."

            case .networkError:
                errorMessage = "No internet connection or request failed."

            case .decodingError:
                errorMessage = "Unable to read product data."
            }
        }
    }

    func resetScanner() {
        scannedCode = ""
        product = nil
        isLoading = false
        lastFetchedCode = ""
        hasScanned = false
        errorMessage = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
