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

            Section {
                NavigationLink(destination: DataSourcesView()) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.blue)
                        Text("Where our data comes from")
                    }
                }
            } header: {
                Text("Transparency")
            } footer: {
                Text("Every ingredient classification cites its sources. Tap any chip to see specifically which sources informed that verdict.")
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

struct DataSourcesView: View {
    var body: some View {
        List {
            Section {
                Text("Every ingredient classification in this app is backed by at least one named, citable source. Tap any chip in a scan result to see which specific sources informed that verdict — each row in the Sources section is tappable and opens the original page in Safari.")
                    .font(.callout)
            } header: {
                Text("How transparency works here")
            }

            Section("Where ingredient data comes from") {
                sourceRow(
                    name: "Open Food Facts",
                    type: "Community-maintained open database",
                    note: "Provides the product info, parsed ingredient list, and vegan/vegetarian flags we use as a proxy signal. Free, open, 4 million products.",
                    url: "https://world.openfoodfacts.org/"
                )
                sourceRow(
                    name: "Wikipedia",
                    type: "Crowd-sourced encyclopedia",
                    note: "Source for the \"What it is\" descriptions on most chips, plus crowd-curated synonym aliases (e.g. \"Pepita\" -> Pumpkin seed).",
                    url: "https://en.wikipedia.org/"
                )
                sourceRow(
                    name: "WorldOfIslam E-number list",
                    type: "Community halal reference",
                    note: "Comprehensive E-number halal status list maintained by the Muslim community. Source for 200+ additional opinions on E-numbers.",
                    url: "https://special.worldofislam.info/Food/numbers.html"
                )
            }

            Section("Where our hand-curated rulings come from") {
                Text("69 hand-written entries cover the most commonly-encountered ingredients (pork, lard, ethanol, wine, gelatin, lecithin, common E-numbers). They are based on:")
                    .font(.callout)
                Text("• Direct scriptural references where applicable (Quran 2:173, 5:3, 5:90) for clear prohibitions like pork and alcohol.")
                    .font(.callout).padding(.leading, 8)
                Text("• Community consensus across the above sources.")
                    .font(.callout).padding(.leading, 8)
                Text("• Wikipedia for definitions and chemical descriptions.")
                    .font(.callout).padding(.leading, 8)
            }

            Section {
                Text("We do NOT yet have authoritative citations from certification bodies (JAKIM Malaysia, LPPOM MUI Indonesia, IFANCA USA, HFA UK, HMC UK, MUIS Singapore). These bodies are the highest authority for halal classification.")
                    .font(.callout)
                Text("Adding them requires obtaining and parsing their published ingredient guidelines — most of which are PDFs in multiple languages. Help is welcome via the open data repo.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("Open the data repo on GitHub",
                     destination: URL(string: "https://github.com/sfc38/ingredient-checker-data")!)
                    .font(.callout)
            } header: {
                Text("What we DON'T have yet")
            }

            Section {
                Text("Some products show an \"On the package\" card with HALAL, KOSHER, VEGAN, VEGETARIAN, ORGANIC, or GLUTEN-FREE labels. These come DIRECTLY from the product packaging via Open Food Facts — they are the manufacturer's own claim.")
                    .font(.callout)
                Text("We pass these claims through unchanged. We do not verify them. Trust them only as much as you trust the manufacturer.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Manufacturer-declared labels")
            }

            Section {
                Text("Informational only — not a fatwa. For definitive rulings, consult a qualified scholar or your local certification body.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Data sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sourceRow(name: String, type: String, note: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name).font(.headline)
                Spacer()
                if let u = URL(string: url) {
                    Link(destination: u) {
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.blue)
                    }
                }
            }
            Text(type).font(.caption).foregroundColor(.secondary).textCase(.uppercase)
            Text(note).font(.callout)
            if let u = URL(string: url) {
                Link(url, destination: u)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 4)
    }
}
