//
//  IngredientCheckApp.swift
//  IngredientCheck
//

import SwiftUI

@main
struct IngredientCheckApp: App {
    @StateObject private var database = IngredientDatabase()
    @StateObject private var history = ScanHistory()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(database)
                .environmentObject(history)
                .task {
                    await database.load()
                }
        }
    }
}
