//
//  DietaryProfile.swift
//  IngredientCheck
//

import Foundation

protocol DietaryProfile {
    var id: String { get }
    var displayName: String { get }
    func label(for status: VerdictStatus) -> String
}

struct HalalProfile: DietaryProfile {
    let id = "halal"
    let displayName = "Halal"
    func label(for status: VerdictStatus) -> String {
        switch status {
        case .allowed:   return "Halal"
        case .forbidden: return "Haram"
        case .caution:   return "Mushbooh"
        case .unknown:   return "No data"
        }
    }
}

struct VeganProfile: DietaryProfile {
    let id = "vegan"
    let displayName = "Vegan"
    func label(for status: VerdictStatus) -> String {
        switch status {
        case .allowed:   return "Vegan"
        case .forbidden: return "Not vegan"
        case .caution:   return "May not be vegan"
        case .unknown:   return "No data"
        }
    }
}

struct VegetarianProfile: DietaryProfile {
    let id = "vegetarian"
    let displayName = "Vegetarian"
    func label(for status: VerdictStatus) -> String {
        switch status {
        case .allowed:   return "Vegetarian"
        case .forbidden: return "Not vegetarian"
        case .caution:   return "May not be vegetarian"
        case .unknown:   return "No data"
        }
    }
}

struct KosherProfile: DietaryProfile {
    let id = "kosher"
    let displayName = "Kosher"
    func label(for status: VerdictStatus) -> String {
        switch status {
        case .allowed:   return "Kosher"
        case .forbidden: return "Not kosher"
        case .caution:   return "Doubtful"
        case .unknown:   return "No data"
        }
    }
}

enum DietaryProfiles {
    static let all: [DietaryProfile] = [
        HalalProfile(),
        VeganProfile(),
        VegetarianProfile(),
        KosherProfile()
    ]

    static let supported: Set<String> = ["halal"]

    static func profile(for id: String) -> DietaryProfile {
        all.first(where: { $0.id == id }) ?? HalalProfile()
    }
}
