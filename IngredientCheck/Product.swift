//
//  Product.swift
//  IngredientCheck
//

import Foundation

struct ProductResponse: Codable {
    let status: Int?
    let product: Product?
}

struct Product: Codable {
    let productName: String?
    let ingredientsText: String?
    let imageUrl: String?
    let imageThumbUrl: String?
    let brands: String?
    let ingredients: [OFFIngredient]?
    let labelsTags: [String]?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case ingredientsText = "ingredients_text"
        case imageUrl = "image_small_url"
        case imageThumbUrl = "image_thumb_url"
        case brands
        case ingredients
        case labelsTags = "labels_tags"
    }

    /// Best image URL for a small thumbnail (recent scans, history list).
    /// Thumb is smaller and loads more reliably; falls back to small if absent.
    var bestThumbnailUrl: String? {
        if let t = imageThumbUrl, !t.isEmpty { return t }
        return imageUrl
    }
}

/// One dietary label declared by the manufacturer on the product packaging
/// (extracted from Open Food Facts' labels_tags field).
struct ManufacturerLabel: Identifiable, Hashable {
    let id: String
    let display: String
    let symbol: String

    static func extract(from product: Product?) -> [ManufacturerLabel] {
        guard let tags = product?.labelsTags else { return [] }
        var seen = Set<String>()
        var result: [ManufacturerLabel] = []
        for tag in tags {
            for label in matchers {
                if label.matches(tag) && !seen.contains(label.id) {
                    seen.insert(label.id)
                    result.append(label)
                }
            }
        }
        return result
    }

    func matches(_ tag: String) -> Bool {
        let lower = tag.lowercased()
        return matchPatterns.contains(where: { lower.contains($0) })
    }

    fileprivate let matchPatterns: [String]

    private init(id: String, display: String, symbol: String, matchPatterns: [String]) {
        self.id = id
        self.display = display
        self.symbol = symbol
        self.matchPatterns = matchPatterns
    }

    static let matchers: [ManufacturerLabel] = [
        ManufacturerLabel(id: "halal",      display: "Halal",      symbol: "moon.stars.fill",
                          matchPatterns: ["halal"]),
        ManufacturerLabel(id: "kosher",     display: "Kosher",     symbol: "star.fill",
                          matchPatterns: ["kosher"]),
        ManufacturerLabel(id: "vegan",      display: "Vegan",      symbol: "leaf.fill",
                          matchPatterns: [":vegan", ":vegan-"]),
        ManufacturerLabel(id: "vegetarian", display: "Vegetarian", symbol: "leaf",
                          matchPatterns: [":vegetarian", "vegetarian-"]),
        ManufacturerLabel(id: "organic",    display: "Organic",    symbol: "checkmark.seal",
                          matchPatterns: ["organic"]),
        ManufacturerLabel(id: "gluten-free",display: "Gluten-free",symbol: "drop.triangle",
                          matchPatterns: ["gluten-free", "no-gluten"]),
    ]
}
