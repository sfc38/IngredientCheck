//
//  IngredientClassifier.swift
//  IngredientCheck
//

import Foundation

@MainActor
struct IngredientClassifier {
    let database: IngredientDatabase
    let profile: DietaryProfile

    /// Classify one OFFIngredient, taking its sub-ingredients into account:
    ///   - classify the parent (top-level) directly
    ///   - recursively classify each sub-ingredient
    ///   - combine: if a sub is more severe than the parent (or the parent
    ///     is unknown), escalate to the sub's status. This way:
    ///       * "Vegetable Fat (Palm, Shea, Illipe)" — parent might be
    ///         unknown but subs are all allowed -> allowed.
    ///       * "Parmesan (Milk, Salt, Enzymes)" — parent caution stays
    ///         caution, with sub list shown in the explanation.
    ///       * "Soya Lecithin (Emulsifier)" — both allowed -> allowed.
    ///       * A hypothetical "Cake (Lard, Sugar)" — parent allowed but
    ///         lard sub is forbidden -> escalate to forbidden.
    func classify(_ ingredient: OFFIngredient) -> Verdict {
        let parentVerdict = classifyOne(ingredient)

        guard let subs = ingredient.ingredients, !subs.isEmpty else {
            return parentVerdict
        }

        let subVerdicts = subs.map { classify($0) }

        // Build the sub-info list so the detail sheet's "What it is"
        // section can show definitions for each parenthesized item.
        let subInfo: [VerdictSubInfo] = subVerdicts.compactMap { sv in
            // Skip if no definition AND status is unknown — nothing useful to show
            guard sv.definition != nil || sv.status != .unknown else { return nil }
            return VerdictSubInfo(
                name: sv.ingredient.displayName,
                definition: sv.definition,
                status: sv.status
            )
        }

        let parentRank = severity(parentVerdict.status)
        let worstSubRank = subVerdicts.map { severity($0.status) }.max() ?? 0
        if worstSubRank <= parentRank {
            // Parent's verdict wins; still attach subInfo for display
            return Verdict(
                ingredient: parentVerdict.ingredient,
                status: parentVerdict.status,
                label: parentVerdict.label,
                definition: parentVerdict.definition,
                commonSources: parentVerdict.commonSources,
                subInfo: subInfo.isEmpty ? nil : subInfo,
                explanation: parentVerdict.explanation,
                sources: parentVerdict.sources,
                disputed: parentVerdict.disputed,
                confidence: parentVerdict.confidence
            )
        }

        // Synthesize a combined verdict.
        let combinedStatus = subVerdicts
            .max(by: { severity($0.status) < severity($1.status) })?
            .status ?? parentVerdict.status
        let contributingSubs = subVerdicts.filter { $0.status == combinedStatus }
        let subNames = contributingSubs
            .map { $0.ingredient.displayName }
            .joined(separator: ", ")

        let leadNote: String
        if parentVerdict.status == .unknown {
            leadNote = "We don't have direct data on the parent ingredient. " +
                "Classification was determined from its sub-ingredient(s): \(subNames)."
        } else {
            leadNote = "Status was elevated by the sub-ingredient(s) listed " +
                "on the label: \(subNames)."
        }

        let mergedExplanation: String = {
            var parts: [String] = [leadNote]
            if parentVerdict.status != .unknown, !parentVerdict.explanation.isEmpty {
                parts.append("Parent (\(ingredient.text ?? ingredient.id ?? "?")): \(parentVerdict.explanation)")
            }
            if let sub = contributingSubs.first, !sub.explanation.isEmpty {
                parts.append("Sub-ingredient (\(sub.ingredient.displayName)): \(sub.explanation)")
            }
            return parts.joined(separator: "\n\n")
        }()

        return Verdict(
            ingredient: ingredient,
            status: combinedStatus,
            label: profile.label(for: combinedStatus),
            definition: parentVerdict.definition ?? contributingSubs.first?.definition,
            commonSources: parentVerdict.commonSources ?? contributingSubs.first?.commonSources,
            subInfo: subInfo.isEmpty ? nil : subInfo,
            explanation: mergedExplanation,
            sources: parentVerdict.sources + (contributingSubs.first?.sources ?? []),
            disputed: parentVerdict.disputed || contributingSubs.contains { $0.disputed },
            confidence: contributingSubs.first?.confidence ?? parentVerdict.confidence
        )
    }

    /// Classify just this one ingredient — no recursion into subs.
    private func classifyOne(_ ingredient: OFFIngredient) -> Verdict {
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

    /// Severity ranking for combining parent + sub verdicts.
    /// forbidden > caution > allowed > unknown
    private func severity(_ status: VerdictStatus) -> Int {
        switch status {
        case .unknown:   return 0
        case .allowed:   return 1
        case .caution:   return 2
        case .forbidden: return 3
        }
    }

    /// Classify a list of top-level parsed ingredients. Each call
    /// recurses into its own sub-ingredients via classify(_:).
    func classify(_ ingredients: [OFFIngredient]) -> [Verdict] {
        ingredients.map { classify($0) }
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
