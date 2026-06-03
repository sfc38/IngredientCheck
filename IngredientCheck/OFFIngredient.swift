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

    /// Build the chip text the user sees. We want it to match what's
    /// printed on the package:
    ///   - prepend OFF's stripped `processing` qualifiers
    ///       ("roasted", "salted", "dried")
    ///   - append OFF's parsed sub-ingredients in parentheses
    ///       e.g. "Leavening Agent" + subs[E500(ii), Yeast]
    ///       -> "Leavening Agent (E500(ii), Yeast)"
    var displayName: String {
        let baseName = text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? id?.replacingOccurrences(of: "en:", with: "").replacingOccurrences(of: "-", with: " ").capitalized
            ?? "Unknown"

        let withProcessing: String = {
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
        }()

        // Append sub-ingredients (the parenthesized "contains" list on a
        // food label). Example: "Vegetable Fat (Palm, Shea, Illipe)".
        guard let subs = ingredients, !subs.isEmpty else { return withProcessing }
        let subNames: [String] = subs.compactMap { sub in
            sub.text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? sub.id?
                    .replacingOccurrences(of: "en:", with: "")
                    .replacingOccurrences(of: "-", with: " ")
                    .capitalized
        }
        guard !subNames.isEmpty else { return withProcessing }
        return "\(withProcessing) (\(subNames.joined(separator: ", ")))"
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
