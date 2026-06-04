//
//  ContentView.swift
//  IngredientCheck
//

import SwiftUI
import VisionKit

struct ContentView: View {
    @AppStorage("rootTab") private var rootTab: Int = 0

    var body: some View {
        TabView(selection: $rootTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)

            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(1)

            NavigationStack { ScanView() }
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
                .tag(2)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
    }
}

struct HomeView: View {
    @AppStorage("profileId") private var profileId: String = "halal"
    @AppStorage("rootTab") private var rootTab: Int = 0
    @EnvironmentObject var database: IngredientDatabase

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer(minLength: 0)
                heroCompact
                profileChip
                scanCTA
                databaseStatusCompact
                howItWorksCompact
                Spacer(minLength: 0)
                Text("Open Food Facts · Informational only — not a fatwa.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCompact: some View {
        VStack(spacing: 8) {
            Image("HomeLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            Text("Ingredient Check")
                .font(.title2)
                .fontWeight(.bold)
            Text("Scan a barcode. Each ingredient gets a color and a verdict.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var profileChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill").font(.caption)
            Text("\(DietaryProfiles.profile(for: profileId).displayName) profile")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.12))
        .clipShape(Capsule())
    }

    private var scanCTA: some View {
        Button {
            rootTab = 2
        } label: {
            Label("Scan Product", systemImage: "barcode.viewfinder")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var databaseStatusCompact: some View {
        NavigationLink(destination: DataSourcesView()) {
            HStack(spacing: 10) {
                Image(systemName: database.file != nil ? "checkmark.circle.fill" : "ellipsis.circle.fill")
                    .foregroundColor(database.file != nil ? .green : .secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(database.file != nil ? "Database ready" : "Loading database…")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    if let file = database.file {
                        Text("\(file.ingredients.count.formatted()) ingredients · v\(file.version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var howItWorksCompact: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepRow(num: 1, text: "Scan a food barcode")
            stepRow(num: 2, text: "See each ingredient as a color chip")
            stepRow(num: 3, text: "Tap a chip for the why and sources")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func stepRow(num: Int, text: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.15)).frame(width: 22, height: 22)
                Text("\(num)").font(.caption2).fontWeight(.semibold).foregroundColor(.blue)
            }
            Text(text).font(.caption)
            Spacer()
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var history: ScanHistory
    @AppStorage("rootTab") private var rootTab: Int = 0

    var body: some View {
        List {
            ForEach(history.items) { item in
                NavigationLink(destination: ScanView(initialBarcode: item.barcode)) {
                    HStack(spacing: 12) {
                        productThumbnail(item)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName).font(.subheadline).fontWeight(.medium)
                            HStack(spacing: 6) {
                                Text(item.date.friendlyRelative)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                if item.forbidden > 0 {
                                    Text("\(item.forbidden) forbidden")
                                        .font(.caption2).foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    history.remove(history.items[index])
                }
            }
        }
        .navigationTitle("Scan history")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { rootTab = 0 } label: {
                    Label("Home", systemImage: "house")
                }
            }
            if !history.items.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) {
                        history.clear()
                    }
                }
            }
        }
        .overlay {
            if history.items.isEmpty {
                Text("No scans yet.").foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func productThumbnail(_ item: ScanHistoryItem) -> some View {
        ScanHistoryThumbnail(item: item)
    }
}

/// Thumbnail for a ScanHistoryItem. Prefers the locally-cached image
/// that ScanHistory wrote to disk on record() so the home page never
/// has to re-fetch from OFF servers. Falls back to AsyncImage from URL,
/// then to a barcode placeholder.
struct ScanHistoryThumbnail: View {
    let item: ScanHistoryItem

    var body: some View {
        if item.hasCachedImage,
           let path = item.localImagePath,
           let ui = UIImage(contentsOfFile: path.path) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else if let urlString = item.bestThumbnailUrl,
                  !urlString.isEmpty,
                  let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color(.systemGray6)
            }
        } else {
            ZStack {
                Color(.systemGray6)
                Image(systemName: "barcode").foregroundColor(.secondary)
            }
        }
    }
}

extension Date {
    /// Bucketed relative time — no live seconds counter. "Just now",
    /// "12 min ago", "3h ago", "Yesterday", "Mon", or a full date.
    var friendlyRelative: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        if interval < 60 { return "Just now" }
        if interval < 3600 {
            let m = Int(interval / 60)
            return "\(m) min ago"
        }
        if Calendar.current.isDateInToday(self) {
            let h = Int(interval / 3600)
            return "\(h)h ago"
        }
        if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        }
        let daysAgo = Calendar.current.dateComponents([.day], from: self, to: now).day ?? 0
        if daysAgo < 7 {
            let f = DateFormatter()
            f.dateFormat = "EEEE"
            return f.string(from: self)
        }
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f.string(from: self)
    }
}

struct ScanView: View {
    let initialBarcode: String?

    @AppStorage("profileId") private var profileId: String = "halal"
    @EnvironmentObject var database: IngredientDatabase
    @EnvironmentObject var history: ScanHistory

    @State private var scannedCode: String
    @State private var lastFetchedCode: String = ""
    @State private var product: Product? = nil
    @State private var isLoading = false
    @State private var hasScanned: Bool
    @State private var errorMessage: String = ""
    @State private var fetchError: ProductFetchError? = nil

    init(initialBarcode: String? = nil) {
        self.initialBarcode = initialBarcode
        let bc = initialBarcode ?? ""
        self._scannedCode = State(initialValue: bc)
        self._hasScanned = State(initialValue: !bc.isEmpty)
    }

    private var profile: DietaryProfile { DietaryProfiles.profile(for: profileId) }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if !hasScanned {
                ScrollView {
                    scannerSection.padding()
                }
            } else {
                ResultView(
                    barcode: scannedCode,
                    product: product,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    fetchError: fetchError,
                    profile: profile,
                    onScanAgain: resetScanner
                )
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if hasScanned {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: resetScanner) {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .accessibilityLabel("Scan another product")
                }
            }
        }
        .onChange(of: scannedCode) { newCode in
            Task { await fetchIfNeeded(barcode: newCode) }
        }
        .task {
            if let bc = initialBarcode, !bc.isEmpty {
                await fetchIfNeeded(barcode: bc)
            }
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
        fetchError = nil
        do {
            let fetched = try await ProductService().fetchProduct(barcode: barcode)
            product = fetched
            let classifier = IngredientClassifier(database: database, profile: profile)
            let verdicts = classifier.classify(fetched.ingredients ?? [])
            history.record(barcode: barcode, product: fetched, verdicts: verdicts)
        } catch let err as ProductFetchError {
            fetchError = err
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
        fetchError = nil
    }
}

struct ResultView: View {
    let barcode: String
    let product: Product?
    let isLoading: Bool
    let errorMessage: String
    let fetchError: ProductFetchError?
    let profile: DietaryProfile
    let onScanAgain: () -> Void

    @EnvironmentObject var database: IngredientDatabase
    @State private var selectedVerdict: Verdict?
    @State private var statusFilter: VerdictStatus?

    private var verdicts: [Verdict] {
        guard let ingredients = product?.ingredients, !ingredients.isEmpty else { return [] }
        let classifier = IngredientClassifier(database: database, profile: profile)
        return classifier.classify(ingredients)
    }

    private var manufacturerLabels: [ManufacturerLabel] {
        ManufacturerLabel.extract(from: product)
    }

    private var visibleVerdicts: [Verdict] {
        guard let f = statusFilter else { return verdicts }
        return verdicts.filter { $0.status == f }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: verdicts.isEmpty ? [] : [.sectionHeaders]) {
                if fetchError == .notFound {
                    productNotFoundCard
                        .padding(.horizontal)
                } else {
                    productCard
                        .padding(.horizontal)

                    if !manufacturerLabels.isEmpty {
                        manufacturerLabelsCard
                            .padding(.horizontal)
                    }

                    if !verdicts.isEmpty {
                        Section {
                            ingredientsCard
                                .padding(.horizontal)
                        } header: {
                            summarySectionHeader
                        }
                    } else if let text = product?.ingredientsText,
                              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              !isLoading {
                        rawIngredientsCard(text)
                            .padding(.horizontal)
                    } else if product != nil, !isLoading {
                        noIngredientsCard
                            .padding(.horizontal)
                    }
                }

                scanAgainButton
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedVerdict) { verdict in
            IngredientDetailSheet(verdict: verdict, profile: profile)
                .presentationDetents([.medium, .large])
        }
    }

    private var productCard: some View {
        HStack(alignment: .top, spacing: 14) {
            if let imageUrl = product?.imageUrl,
               let url = URL(string: imageUrl),
               !imageUrl.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color(.systemGray6)
                        ProgressView().scaleEffect(0.8)
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 4) {
                if let name = product?.productName, !name.isEmpty {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .copyableField(label: "product name", value: name)
                } else if isLoading && product == nil {
                    Text("Loading…")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                if let brands = product?.brands, !brands.isEmpty {
                    Text(brands)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .copyableField(label: "brand", value: brands)
                }
                Text("Barcode: \(barcode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .copyableField(label: "barcode", value: barcode)

                if isLoading && product != nil {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Updating…").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
                if !errorMessage.isEmpty && !isLoading {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .textSelection(.enabled)  // long-press any text (barcode, name, brand) to copy
    }

    private var summarySectionHeader: some View {
        SummaryHeader(
            summary: VerdictSummary(verdicts: verdicts),
            profile: profile,
            filter: $statusFilter
        )
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients").font(.headline)
                Spacer()
                if statusFilter != nil {
                    Text("\(visibleVerdicts.count) of \(verdicts.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(verdicts.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if visibleVerdicts.isEmpty {
                Text("No ingredients match the selected filter.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 10) {
                    ForEach(visibleVerdicts) { verdict in
                        IngredientChip(verdict: verdict) { selectedVerdict = verdict }
                    }
                }
            }

            Text("Tap an ingredient to see why.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var scanAgainButton: some View {
        Button(action: onScanAgain) {
            Label("Scan Another", systemImage: "barcode.viewfinder")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 4)
    }

    private var productNotFoundCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "barcode.viewfinder")
                    .foregroundColor(.orange)
                Text("Product not in Open Food Facts").font(.headline)
            }
            Text("We scanned the barcode but Open Food Facts — our product data source — doesn't have this product in their database.")
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "barcode").font(.caption).foregroundColor(.secondary)
                Text(barcode).font(.subheadline).fontWeight(.medium)
            }
            .padding(.vertical, 4)

            Text("You can add the product yourself in a couple of minutes — open it on Open Food Facts and fill in the name, brand, image, and ingredients. Once they have it, this app picks it up automatically on your next scan.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let url = URL(string: "https://world.openfoodfacts.org/cgi/product.pl?type=add&code=\(barcode)") {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle").font(.caption)
                        Text("Add to Open Food Facts").font(.caption).fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            if let url = URL(string: "https://world.openfoodfacts.org/product/\(barcode)") {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square").font(.caption)
                        Text("Try opening on Open Food Facts anyway").font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .textSelection(.enabled)
    }

    private var noIngredientsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
                Text("No ingredient information").font(.headline)
            }
            Text("Open Food Facts doesn't have an ingredient list for this product yet, so we have nothing to classify. The product exists in their database, but the ingredients section is empty.")
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("You can help fill the gap — open the product on Open Food Facts and add the ingredient list from the package. Once OFF has it, this app picks it up automatically on your next scan.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let url = URL(string: "https://world.openfoodfacts.org/product/\(barcode)") {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square").font(.caption)
                        Text("Open in Open Food Facts").font(.caption).fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var manufacturerLabelsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tag.fill").foregroundColor(.purple)
                Text("On the package").font(.headline)
            }
            Text("These labels come from the product packaging itself, not our ingredient analysis. We're showing what the manufacturer claims; trust the claim only as much as you trust the manufacturer.")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(manufacturerLabels) { label in
                    HStack(spacing: 4) {
                        Image(systemName: label.symbol).font(.caption)
                        Text(label.display).font(.caption).fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.12))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
                }
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(IngredientDatabase())
            .environmentObject(ScanHistory())
    }
}
