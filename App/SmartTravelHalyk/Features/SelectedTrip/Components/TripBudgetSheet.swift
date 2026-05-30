import SwiftUI

struct TripBudgetSheet: View {
    @Bindable var viewModel: SelectedTripViewModel
    @Environment(\.dismiss) private var dismiss

    private var positiveItems: [BudgetItem] {
        viewModel.effectiveBudget.items.filter { $0.amount > 0 }
    }
    private var discountItems: [BudgetItem] {
        viewModel.effectiveBudget.items.filter { $0.amount < 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Total + mode picker ────────────────────────
                    VStack(spacing: 12) {
                        Text(viewModel.effectiveTotalCost.displayString)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.3), value: viewModel.effectiveTotalCost.amount)

                        ModePillPicker(viewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // ── Tradeoff label ─────────────────────────────
                    if let label = viewModel.currentTradeoffLabel {
                        Text(label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, -12)
                    }

                    // ── Mode comparison row ────────────────────────
                    ModeComparisonRow(viewModel: viewModel)
                        .padding(.horizontal, 16)

                    // ── Category tiles ─────────────────────────────
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(positiveItems, id: \.category) { item in
                            BudgetTile(item: item)
                        }
                    }
                    .padding(.horizontal, 16)

                    // ── Cashback discount ──────────────────────────
                    ForEach(discountItems, id: \.category) { item in
                        CashbackDiscountRow(item: item)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Mode pill picker (dropdown style)

private struct ModePillPicker: View {
    @Bindable var viewModel: SelectedTripViewModel

    var body: some View {
        Menu {
            ForEach(viewModel.trip.availableModes) { mode in
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        viewModel.selectedMode = mode
                    }
                } label: {
                    HStack {
                        Text(mode.fullTitle)
                        if viewModel.selectedMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.selectedMode.fullTitle)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .animation(.smooth(duration: 0.25), value: viewModel.selectedMode)
    }
}

// MARK: - Mode comparison strip

private struct ModeComparisonRow: View {
    let viewModel: SelectedTripViewModel

    var body: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.trip.availableModes) { mode in
                let variant = viewModel.trip.modeVariants[mode]
                let isSelected = viewModel.selectedMode == mode

                VStack(spacing: 3) {
                    Text(mode.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                    if let v = variant {
                        Text("\(Int(v.totalCost / 1_000))k")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 10))
                .animation(.smooth(duration: 0.2), value: isSelected)
            }
        }
    }
}

// MARK: - Budget tile

private struct BudgetTile: View {
    let item: BudgetItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconForCategory(item.category))
                .font(.title2.weight(.medium))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Spacer()

            Text(item.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(item.absDisplayString)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func iconForCategory(_ cat: BudgetCategory) -> String {
        switch cat {
        case .flights:            return "airplane"
        case .hotels:             return "bed.double.fill"
        case .localTransport:     return "bus.fill"
        case .intercityTransport: return "train.side.front.car"
        case .food:               return "fork.knife"
        case .activities:         return "binoculars.fill"
        case .events:             return "ticket.fill"
        case .visa:               return "doc.badge.arrow.up"
        case .insurance:          return "shield.fill"
        case .souvenirs:          return "bag.fill"
        case .buffer:             return "plus.circle.fill"
        case .cashbackDiscount:   return "creditcard.fill"
        }
    }
}

// MARK: - Cashback discount row

private struct CashbackDiscountRow: View {
    let item: BudgetItem

    var body: some View {
        HStack {
            Label(item.title, systemImage: "creditcard.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
            Spacer()
            Text("− \(item.absDisplayString)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(14)
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1)
        }
    }
}

// MARK: - TripMode helpers

extension TripMode {
    var fullTitle: String {
        switch self {
        case .economy:  return "Budget trip"
        case .balanced: return "Balanced"
        case .comfort:  return "Comfort"
        }
    }
}

// MARK: - Preview

#Preview {
    TripBudgetSheet(viewModel: .preview)
}
