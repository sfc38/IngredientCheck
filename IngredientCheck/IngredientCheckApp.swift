//
//  IngredientCheckApp.swift
//  IngredientCheck
//

import SwiftUI

@main
struct IngredientCheckApp: App {
    @StateObject private var database = IngredientDatabase()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(database)
                .task {
                    await database.load()
                }
        }
    }
}
