//
//  ScanHistory.swift
//  IngredientCheck
//

import Foundation

struct ScanHistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    let barcode: String
    let productName: String?
    let brands: String?
    let imageUrl: String?
    let imageThumbUrl: String?
    let date: Date
    let allowed: Int
    let caution: Int
    let forbidden: Int
    let unknown: Int

    init(barcode: String, product: Product?, verdicts: [Verdict]) {
        self.id = UUID()
        self.barcode = barcode
        self.productName = product?.productName
        self.brands = product?.brands
        self.imageUrl = product?.imageUrl
        self.imageThumbUrl = product?.imageThumbUrl
        self.date = Date()
        self.allowed   = verdicts.filter { $0.status == .allowed }.count
        self.caution   = verdicts.filter { $0.status == .caution }.count
        self.forbidden = verdicts.filter { $0.status == .forbidden }.count
        self.unknown   = verdicts.filter { $0.status == .unknown }.count
    }

    var displayName: String {
        productName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Product \(barcode)"
    }

    var totalChips: Int { allowed + caution + forbidden + unknown }

    /// Best small-image URL for thumbnails. Tries thumb first, falls back to small.
    var bestThumbnailUrl: String? {
        if let t = imageThumbUrl, !t.isEmpty { return t }
        return imageUrl
    }
}

@MainActor
final class ScanHistory: ObservableObject {
    @Published private(set) var items: [ScanHistoryItem] = []

    private let storageKey = "scanHistory.v1"
    private let maxItems = 50

    init() {
        load()
    }

    func record(barcode: String, product: Product?, verdicts: [Verdict]) {
        let item = ScanHistoryItem(barcode: barcode, product: product, verdicts: verdicts)
        items.removeAll { $0.barcode == barcode }
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        save()
    }

    func clear() {
        items = []
        save()
    }

    func remove(_ item: ScanHistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([ScanHistoryItem].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
