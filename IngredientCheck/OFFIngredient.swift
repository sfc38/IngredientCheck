//
//  OFFIngredient.swift
//  IngredientCheck
//

import Foundation

struct OFFIngredient: Codable, Identifiable, Hashable {
    let id: String?
    let text: String?
    let percentEstimate: Double?
    let vegan: String?
    let vegetarian: String?
    let ingredients: [OFFIngredient]?

    enum CodingKeys: String, CodingKey {
        case id, text, vegan, vegetarian, ingredients
        case percentEstimate = "percent_estimate"
    }

    var displayName: String {
        text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? id?.replacingOccurrences(of: "en:", with: "").replacingOccurrences(of: "-", with: " ").capitalized
            ?? "Unknown"
    }

    var stableId: String {
        id ?? text ?? UUID().uuidString
    }

    var leaves: [OFFIngredient] {
        if let subs = ingredients, !subs.isEmpty {
            return subs.flatMap { $0.leaves }
        }
        return [self]
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
