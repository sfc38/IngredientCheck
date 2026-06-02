//
//  IngredientDatabase.swift
//  IngredientCheck
//

import Foundation

struct DBFile: Codable {
    let version: String
    let profiles: [String]
    let ingredients: [DBIngredient]
}

struct DBIngredient: Codable {
    let id: String
    let names: [String]
    let eNumber: String?
    let category: String
    let definition: String?
    let commonSources: [DBCommonSource]?
    let rulings: [String: DBRuling]
    let lastReviewed: String?

    enum CodingKeys: String, CodingKey {
        case id, names, category, rulings, definition
        case eNumber = "e_number"
        case commonSources = "common_sources"
        case lastReviewed = "last_reviewed"
    }
}

struct DBCommonSource: Codable {
    let name: String
    let note: String?
}

struct DBRuling: Codable {
    let effectiveStatus: String
    let explanation: String
    let disputed: Bool?
    let confidence: String
    let opinions: [VerdictSource]

    enum CodingKeys: String, CodingKey {
        case explanation, confidence, opinions, disputed
        case effectiveStatus = "effective_status"
    }
}

@MainActor
final class IngredientDatabase: ObservableObject {
    @Published private(set) var file: DBFile?
    @Published private(set) var loadState: LoadState = .idle

    enum LoadState { case idle, loading, loaded, failed(String) }

    private var byId: [String: DBIngredient] = [:]
    private var byName: [String: DBIngredient] = [:]

    static let remoteURL = URL(string: "https://raw.githubusercontent.com/sfc38/ingredient-checker-data/main/data/ingredients.json")!

    private var cachedFileURL: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ingredients.json")
    }

    func load() async {
        loadState = .loading

        if let cached = loadCached() {
            apply(cached)
        } else if let bundled = loadBundled() {
            apply(bundled)
        }

        do {
            let remote = try await fetchRemote()
            apply(remote)
            saveCache(remote)
            loadState = .loaded
        } catch {
            loadState = file == nil ? .failed(error.localizedDescription) : .loaded
        }
    }

    func lookup(id: String?) -> DBIngredient? {
        guard let id = id else { return nil }
        if let hit = byId[id] { return hit }
        let normalized = id.lowercased()
        if let hit = byName[normalized] { return hit }
        return nil
    }

    func lookup(name: String) -> DBIngredient? {
        let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return byName[key]
    }

    private func apply(_ db: DBFile) {
        self.file = db
        self.byId = Dictionary(uniqueKeysWithValues: db.ingredients.map { ($0.id, $0) })
        var nameIndex: [String: DBIngredient] = [:]
        for ing in db.ingredients {
            for name in ing.names {
                nameIndex[name.lowercased()] = ing
            }
        }
        self.byName = nameIndex
    }

    private func loadBundled() -> DBFile? {
        guard let url = Bundle.main.url(forResource: "ingredients", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DBFile.self, from: data)
    }

    private func loadCached() -> DBFile? {
        guard let url = cachedFileURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DBFile.self, from: data)
    }

    private func saveCache(_ db: DBFile) {
        guard let url = cachedFileURL,
              let data = try? JSONEncoder().encode(db) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func fetchRemote() async throws -> DBFile {
        var request = URLRequest(url: Self.remoteURL)
        request.timeoutInterval = 10
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(DBFile.self, from: data)
    }
}
