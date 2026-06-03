//
//  Verdict.swift
//  IngredientCheck
//

import SwiftUI

enum VerdictStatus: String, Codable, CaseIterable {
    case allowed, forbidden, caution, unknown

    var color: Color {
        switch self {
        case .allowed:   return .green
        case .forbidden: return .red
        case .caution:   return .orange
        case .unknown:   return .gray
        }
    }

    var sortOrder: Int {
        switch self {
        case .forbidden: return 0
        case .caution:   return 1
        case .unknown:   return 2
        case .allowed:   return 3
        }
    }
}

struct VerdictSource: Codable, Hashable, Identifiable {
    let source: String
    let type: String
    let status: String
    let note: String?
    let ref: String?

    var id: String { source + (ref ?? "") + (note ?? "") }

    var typeLabel: String {
        switch type {
        case "authority":  return "Authority"
        case "community":  return "Community"
        case "scientific": return "Scientific"
        case "scripture":  return "Scripture"
        default:           return type.capitalized
        }
    }
}

struct VerdictCommonSource: Hashable, Identifiable {
    let name: String
    let note: String?
    var id: String { name + "::" + (note ?? "") }
}

/// "What it is" info for one sub-ingredient inside a compound parent.
/// Example: "Soya Lecithin (E322)" -> subInfo entry { name: "E322",
/// definition: "E322 is the E-number for lecithin..." }.
struct VerdictSubInfo: Hashable, Identifiable {
    let name: String
    let definition: String?
    let status: VerdictStatus
    var id: String { name + "::" + (definition ?? "") }
}

struct Verdict: Identifiable, Hashable {
    let id = UUID()
    let ingredient: OFFIngredient
    let status: VerdictStatus
    let label: String
    let definition: String?
    let commonSources: [VerdictCommonSource]?
    let subInfo: [VerdictSubInfo]?
    let explanation: String
    let sources: [VerdictSource]
    let disputed: Bool
    let confidence: String

    init(
        ingredient: OFFIngredient,
        status: VerdictStatus,
        label: String,
        definition: String? = nil,
        commonSources: [VerdictCommonSource]? = nil,
        subInfo: [VerdictSubInfo]? = nil,
        explanation: String,
        sources: [VerdictSource],
        disputed: Bool,
        confidence: String
    ) {
        self.ingredient = ingredient
        self.status = status
        self.label = label
        self.definition = definition
        self.commonSources = commonSources
        self.subInfo = subInfo
        self.explanation = explanation
        self.sources = sources
        self.disputed = disputed
        self.confidence = confidence
    }

    static func == (lhs: Verdict, rhs: Verdict) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
