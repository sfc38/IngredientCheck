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

struct Verdict: Identifiable, Hashable {
    let id = UUID()
    let ingredient: OFFIngredient
    let status: VerdictStatus
    let label: String
    let explanation: String
    let sources: [VerdictSource]
    let disputed: Bool
    let confidence: String

    static func == (lhs: Verdict, rhs: Verdict) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
