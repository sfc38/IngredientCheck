//
//  SettingsView.swift
//  IngredientCheck
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("profileId") private var profileId: String = "halal"
    @EnvironmentObject var database: IngredientDatabase

    var body: some View {
        Form {
            Section("Active dietary profile") {
                Picker("Profile", selection: $profileId) {
                    ForEach(DietaryProfiles.all, id: \.id) { profile in
                        HStack {
                            Text(profile.displayName)
                            if !DietaryProfiles.supported.contains(profile.id) {
                                Text("coming soon")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(profile.id)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onChange(of: profileId) { newValue in
                    if !DietaryProfiles.supported.contains(newValue) {
                        profileId = "halal"
                    }
                }
            }

            Section("Database") {
                if let file = database.file {
                    LabeledContent("Version", value: file.version)
                    LabeledContent("Ingredients", value: "\(file.ingredients.count)")
                } else {
                    Text("Database not loaded").foregroundColor(.secondary)
                }
                LabeledContent("Source", value: "github.com/sfc38/ingredient-checker-data")
                    .font(.caption)
            }

            Section("About") {
                Text("Informational only. Not a fatwa. For definitive rulings, consult a qualified scholar or your local certification body.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section {
                LabeledContent("App version", value: appVersion)
                LabeledContent("Product data", value: "Open Food Facts")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
