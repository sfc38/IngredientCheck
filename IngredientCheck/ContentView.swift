//
//  ContentView.swift
//  IngredientCheck
//

import SwiftUI
import VisionKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

struct HomeView: View {
    @AppStorage("profileId") private var profileId: String = "halal"

    var body: some View {
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

                    Text("Scan food barcodes and check each ingredient against your dietary profile.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 6) {
                        Text("Profile:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(DietaryProfiles.profile(for: profileId).displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
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

                Text("Product data: Open Food Facts")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

struct ScanView: View {
    @AppStorage("profileId") private var profileId: String = "halal"

    @State private var scannedCode: String = ""
    @State private var lastFetchedCode: String = ""
    @State private var product: Product? = nil
    @State private var isLoading = false
    @State private var hasScanned = false
    @State private var errorMessage: String = ""

    private var profile: DietaryProfile { DietaryProfiles.profile(for: profileId) }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if !hasScanned {
                        scannerSection
                    } else {
                        ResultView(
                            barcode: scannedCode,
                            product: product,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            profile: profile,
                            onScanAgain: resetScanner
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scannedCode) { newCode in
            Task { await fetchIfNeeded(barcode: newCode) }
        }
    }

    private var scannerSection: some View {
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

    private func fetchIfNeeded(barcode: String) async {
        guard !barcode.isEmpty, barcode != lastFetchedCode else { return }
        lastFetchedCode = barcode
        hasScanned = true
        isLoading = true
        product = nil
        errorMessage = ""
        do {
            product = try await ProductService().fetchProduct(barcode: barcode)
        } catch let err as ProductFetchError {
            errorMessage = err.localizedDescription
        } catch {
            errorMessage = "Unexpected error."
        }
        isLoading = false
    }

    private func resetScanner() {
        scannedCode = ""
        lastFetchedCode = ""
        product = nil
        isLoading = false
        hasScanned = false
        errorMessage = ""
    }
}

struct ResultView: View {
    let barcode: String
    let product: Product?
    let isLoading: Bool
    let errorMessage: String
    let profile: DietaryProfile
    let onScanAgain: () -> Void

    @EnvironmentObject var database: IngredientDatabase
    @State private var selectedVerdict: Verdict?

    private var verdicts: [Verdict] {
        guard let ingredients = product?.ingredients, !ingredients.isEmpty else { return [] }
        let classifier = IngredientClassifier(database: database, profile: profile)
        return classifier.classify(ingredients).sorted { $0.status.sortOrder < $1.status.sortOrder }
    }

    var body: some View {
        VStack(spacing: 16) {
            productCard
            if !verdicts.isEmpty {
                summaryCard
                ingredientsCard
            } else if let text = product?.ingredientsText,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !isLoading {
                rawIngredientsCard(text)
            }
            scanAgainButton
        }
        .sheet(item: $selectedVerdict) { verdict in
            IngredientDetailSheet(verdict: verdict, profile: profile)
                .presentationDetents([.medium, .large])
        }
    }

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageUrl = product?.imageUrl,
               let url = URL(string: imageUrl),
               !imageUrl.isEmpty {
                HStack {
                    Spacer()
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 140)
                    Spacer()
                }
            }
            if let name = product?.productName, !name.isEmpty {
                Text(name)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            if let brands = product?.brands, !brands.isEmpty {
                Text(brands)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("Barcode: \(barcode)")
                .font(.caption)
                .foregroundColor(.secondary)
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading product…").foregroundColor(.secondary)
                }
            }
            if !errorMessage.isEmpty && !isLoading {
                Text(errorMessage).foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var summaryCard: some View {
        SummaryHeader(summary: VerdictSummary(verdicts: verdicts), profile: profile)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients (\(verdicts.count))")
                .font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(verdicts) { verdict in
                    IngredientChip(verdict: verdict) { selectedVerdict = verdict }
                }
            }
            Text("Tap an ingredient to see why.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func rawIngredientsCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Limited data").font(.headline)
            }
            Text("Open Food Facts didn't parse this product's ingredients into a structured list. Showing the raw text for reference.")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var scanAgainButton: some View {
        Button(action: onScanAgain) {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(IngredientDatabase())
    }
}
