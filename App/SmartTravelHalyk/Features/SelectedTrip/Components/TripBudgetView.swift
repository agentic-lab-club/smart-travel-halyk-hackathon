import SwiftUI

struct TripBudgetView: View {
    let budget: BudgetBreakdown

    private var positiveItems: [BudgetItem] { budget.items.filter { $0.amount > 0 } }
    private var discountItems: [BudgetItem] { budget.items.filter { $0.amount < 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BudgetTotalRow(budget: budget)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(positiveItems, id: \.category) { item in
                    BudgetItemTile(item: item)
                }
            }

            if !discountItems.isEmpty {
                VStack(spacing: 8) {
                    ForEach(discountItems, id: \.category) { item in
                        BudgetDiscountRow(item: item)
                    }
                }
            }
        }
    }
}

private struct BudgetTotalRow: View {
    let budget: BudgetBreakdown

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(budget.total.displayString)
                    .font(.title2.bold())
                Text("Total estimate · \(budget.total.confidence.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ConfidenceBadge(confidence: budget.total.confidence)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct BudgetItemTile: View {
    let item: BudgetItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: iconForCategory(item.category))
                .font(.title3.weight(.medium))
                .foregroundStyle(.green)

            Text(item.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(item.absDisplayString)
                .font(.subheadline.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func iconForCategory(_ cat: BudgetCategory) -> String {
        switch cat {
        case .flights:            return "airplane"
        case .hotels:             return "bed.double.fill"
        case .localTransport:     return "bus.fill"
        case .intercityTransport: return "train.side.front.car"
        case .food:               return "fork.knife"
        case .activities:         return "star.fill"
        case .events:             return "ticket.fill"
        case .visa:               return "doc.badge.arrow.up"
        case .insurance:          return "shield.fill"
        case .souvenirs:          return "bag.fill"
        case .buffer:             return "plus.circle.fill"
        case .cashbackDiscount:   return "creditcard.fill"
        }
    }
}

private struct BudgetDiscountRow: View {
    let item: BudgetItem

    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)

            Text(item.title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Text(item.absDisplayString)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(12)
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct ConfidenceBadge: View {
    let confidence: Confidence

    var body: some View {
        Text(confidence.label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch confidence {
        case .low:    return .red
        case .medium: return .orange
        case .high:   return .green
        }
    }
}

extension Confidence {
    var label: String {
        switch self {
        case .low:    return "Low confidence"
        case .medium: return "Estimated"
        case .high:   return "High confidence"
        }
    }
}

extension BudgetItem {
    var absDisplayString: String {
        "\(Int(abs(amount)).formatted(.number.grouping(.automatic))) \(currency.rawValue)"
    }
}
