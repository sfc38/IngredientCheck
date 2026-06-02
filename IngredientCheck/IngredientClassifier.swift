//
//  IngredientClassifier.swift
//  IngredientCheck
//

import Foundation

@MainActor
struct IngredientClassifier {
    let database: IngredientDatabase
    let profile: DietaryProfile

    func classify(_ ingredient: OFFIngredient) -> Verdict {
        if let dbEntry = database.lookup(id: ingredient.id)
            ?? database.lookup(name: ingredient.text ?? ""),
           let ruling = dbEntry.rulings[profile.id] {
            let status = VerdictStatus(rawValue: ruling.effectiveStatus) ?? .unknown
            return Verdict(
                ingredient: ingredient,
                status: status,
                label: profile.label(for: status),
                definition: dbEntry.definition,
                commonSources: dbEntry.commonSources?.map {
                    VerdictCommonSource(name: $0.name, note: $0.note)
                },
                explanation: ruling.explanation,
                sources: ruling.opinions,
                disputed: ruling.disputed ?? false,
                confidence: ruling.confidence
            )
        }

        if let fallback = offTaxonomyFallback(ingredient) { return fallback }

        return Verdict(
            ingredient: ingredient,
            status: .unknown,
            label: profile.label(for: .unknown),
            explanation: "We don't have data on this ingredient. Verify with the manufacturer or a certification body.",
            sources: [],
            disputed: false,
            confidence: "low"
        )
    }

    func classify(_ ingredients: [OFFIngredient]) -> [Verdict] {
        ingredients.flatMap { $0.leaves }.map { classify($0) }
    }

    private func offTaxonomyFallback(_ ingredient: OFFIngredient) -> Verdict? {
        guard profile.id == "halal" else { return nil }

        if ingredient.vegan == "yes" {
            return Verdict(
                ingredient: ingredient,
                status: .allowed,
                label: profile.label(for: .allowed),
                explanation: "Open Food Facts marks this ingredient as plant-based. Plant-based ingredients are generally considered halal. (This fallback does not detect alcohol-derived ingredients — when in doubt, verify.)",
                sources: [VerdictSource(source: "Open Food Facts taxonomy", type: "community", status: "allowed", note: "vegan: yes", ref: nil)],
                disputed: false,
                confidence: "low"
            )
        }

        if ingredient.vegan == "no" || ingredient.vegetarian == "no" {
            return Verdict(
                ingredient: ingredient,
                status: .caution,
                label: profile.label(for: .caution),
                explanation: "Open Food Facts marks this ingredient as animal-derived. Halal status depends on the source animal and slaughter method; verify with the manufacturer.",
                sources: [VerdictSource(source: "Open Food Facts taxonomy", type: "community", status: "caution", note: "non-vegetarian", ref: nil)],
                disputed: false,
                confidence: "low"
            )
        }

        if ingredient.vegan == "maybe" || ingredient.vegetarian == "maybe" {
            return Verdict(
                ingredient: ingredient,
                status: .caution,
                label: profile.label(for: .caution),
                explanation: "Open Food Facts is uncertain about the source of this ingredient. Verify with the manufacturer.",
                sources: [VerdictSource(source: "Open Food Facts taxonomy", type: "community", status: "caution", note: "source uncertain", ref: nil)],
                disputed: false,
                confidence: "low"
            )
        }

        return nil
    }
}

struct VerdictSummary {
    let counts: [VerdictStatus: Int]
    let total: Int

    init(verdicts: [Verdict]) {
        var c: [VerdictStatus: Int] = [.allowed: 0, .forbidden: 0, .caution: 0, .unknown: 0]
        for v in verdicts { c[v.status, default: 0] += 1 }
        self.counts = c
        self.total = verdicts.count
    }

    func count(_ status: VerdictStatus) -> Int { counts[status] ?? 0 }
}
