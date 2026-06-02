//
//  UIComponents.swift
//  IngredientCheck
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = layout(subviews: subviews, maxWidth: maxWidth)
        return CGSize(width: maxWidth.isFinite ? maxWidth : result.widthUsed, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, maxWidth: bounds.width)
        for placement in result.placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.x, y: bounds.minY + placement.y),
                proposal: ProposedViewSize(width: placement.size.width, height: placement.size.height)
            )
        }
    }

    private struct Placement {
        let index: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGSize
    }

    private struct LayoutResult {
        let placements: [Placement]
        let height: CGFloat
        let widthUsed: CGFloat
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> LayoutResult {
        var placements: [Placement] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                widestRow = max(widestRow, x - spacing)
                x = 0
                rowHeight = 0
            }
            placements.append(Placement(index: index, x: x, y: y, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        widestRow = max(widestRow, x - spacing)
        return LayoutResult(placements: placements, height: y + rowHeight, widthUsed: widestRow)
    }
}

struct IngredientChip: View {
    let verdict: Verdict
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(verdict.status.color)
                    .frame(width: 8, height: 8)
                Text(verdict.ingredient.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if verdict.disputed {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(verdict.status.color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(verdict.status.color.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct SummaryHeader: View {
    let summary: VerdictSummary
    let profile: DietaryProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary — \(profile.displayName) profile")
                .font(.headline)

            HStack(spacing: 12) {
                summaryPill(.forbidden, label: profile.label(for: .forbidden))
                summaryPill(.caution,   label: profile.label(for: .caution))
                summaryPill(.allowed,   label: profile.label(for: .allowed))
                summaryPill(.unknown,   label: profile.label(for: .unknown))
            }
        }
    }

    @ViewBuilder
    private func summaryPill(_ status: VerdictStatus, label: String) -> some View {
        let count = summary.count(status)
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(count > 0 ? status.color : .secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(count > 0 ? status.color.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct IngredientDetailSheet: View {
    let verdict: Verdict
    let profile: DietaryProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(verdict.status.color)
                            .frame(width: 14, height: 14)
                        Text(verdict.label)
                            .font(.title3)
                            .fontWeight(.semibold)
                        if verdict.disputed {
                            Text("Disputed")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        confidenceBadge
                    }

                    if let definition = verdict.definition, !definition.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What it is").font(.headline)
                            Text(definition).font(.body)
                        }
                    }

                    if let sources = verdict.commonSources, !sources.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common sources").font(.headline)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(sources) { src in
                                    commonSourceRow(src)
                                }
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verdict").font(.headline)
                        Text(verdict.explanation).font(.body)
                    }

                    if !verdict.sources.isEmpty {
                        Divider()
                        Text("Sources")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(verdict.sources) { source in
                                sourceRow(source)
                            }
                        }
                    }

                    Divider()
                    Text("Informational only. Not a fatwa. For definitive rulings, consult a qualified scholar or your local certification body.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle(verdict.ingredient.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var confidenceBadge: some View {
        let (color, text): (Color, String) = {
            switch verdict.confidence {
            case "high":   return (.green, "High confidence")
            case "medium": return (.blue, "Medium confidence")
            case "low":    return (.gray, "Low confidence")
            default:       return (.gray, verdict.confidence)
            }
        }()
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func sourceRow(_ source: VerdictSource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(source.source)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(source.typeLabel)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            if let note = source.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let ref = source.ref, !ref.isEmpty {
                Text(ref)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func commonSourceRow(_ source: VerdictCommonSource) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(noteColor(source.note))
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name).font(.body)
                if let note = source.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(noteColor(note))
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func noteColor(_ note: String?) -> Color {
        guard let raw = note?.lowercased() else { return .secondary }
        let isHaramish = raw.contains("haram") || raw.contains("forbidden")
        let isHalalish = raw.contains("halal") || raw.contains("allowed")
        let isConditional = raw.contains(" if ") || raw.contains("only") || raw.contains("depending") || raw.contains("mushbooh") || raw.contains("disputed") || raw.contains("doubtful")
        if isHaramish && !isHalalish && !isConditional { return .red }
        if isHalalish && !isHaramish && !isConditional { return .green }
        return .orange
    }
}
