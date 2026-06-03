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
    let processing: String?

    enum CodingKeys: String, CodingKey {
        case id, text, vegan, vegetarian, ingredients, processing
        case percentEstimate = "percent_estimate"
    }

    /// OFF strips processing words ("roasted", "salted", "dried") out of
    /// the ingredient text and stores them in a separate `processing`
    /// field. We prepend them back so the chip matches what's on the
    /// label: e.g. en:cashew + processing:"en:roasted" -> "Roasted cashews".
    var displayName: String {
        let baseName = text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? id?.replacingOccurrences(of: "en:", with: "").replacingOccurrences(of: "-", with: " ").capitalized
            ?? "Unknown"

        guard let proc = processing, !proc.isEmpty else { return baseName }
        let lowerBase = baseName.lowercased()
        let modifiers: [String] = proc.split(separator: ",").compactMap { rawTag in
            let tag = rawTag.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "-", with: " ")
            guard !tag.isEmpty, !lowerBase.contains(tag.lowercased()) else { return nil }
            return tag.capitalized
        }
        guard !modifiers.isEmpty else { return baseName }
        return modifiers.joined(separator: ", ") + " " + baseName
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
