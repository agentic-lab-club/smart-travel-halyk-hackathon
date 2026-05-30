import SwiftUI

// MARK: - Trip header

struct TripHeaderView: View {
    @Bindable var viewModel: SelectedTripViewModel
    @State private var showBudgetSheet = false
    @State private var showPeoplePicker = false

    var trip: TripDetailsResponse { viewModel.trip }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 10) {
                Text(viewModel.destinationCity)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(trip.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Label(dateRangeText, systemImage: "calendar")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())

                    Button {
                        showPeoplePicker = true
                    } label: {
                        Label(travelerSummary, systemImage: "person.fill")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showPeoplePicker) {
                        PeopleCountSheet(adultCount: $viewModel.adultCount, childCount: $viewModel.childCount)
                            .presentationDetents([.height(280)])
                            .presentationDragIndicator(.visible)
                    }
                }

                HStack {
                    if let visa = trip.visa {
                        VisaStatusBadge(status: visa.status)
                    }

                    RatingBadge(rating: 4.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
                .frame(height: 20)

            Button {
                showBudgetSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(viewModel.effectiveTotalCost.displayString)
                            .font(.title2.bold())
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.3), value: viewModel.effectiveTotalCost.amount)

                        Spacer()

                        KnockoutIconStack(
                            icons: ["airplane", "key.fill", "building.columns.fill"],
                            circleSize: 40,
                            shift: 30,
                            circleColor: Color(.tertiarySystemGroupedBackground),
                            iconColor: .secondary
                        )
                    }

                    Text("Approximate trip cost")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .frame(height: 100)
                .background(.secondary.quinary, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showBudgetSheet) {
                TripBudgetSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var travelerSummary: String {
        let adults = viewModel.adultCount
        let children = viewModel.childCount
        if children == 0 { return "\(adults)" }
        return "\(adults + children)"
    }

    private var dateRangeText: String {
        let start = trip.startDate.shortFormatted
        let end = trip.endDate.shortFormatted
        return "\(start) – \(end)"
    }
}

private struct RatingBadge: View {
    let rating: Double

    var body: some View {
        Label(String(format: "%.1f", rating), systemImage: "star.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.12), in: Capsule())
    }
}

private struct PeopleCountSheet: View {
    @Binding var adultCount: Int
    @Binding var childCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Travelers")
                .font(.headline)
                .padding(.top, 24)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                TravelerRow(
                    icon: "person.fill",
                    label: "Adults",
                    count: $adultCount,
                    minimum: 1
                )
                Divider().padding(.leading, 56)
                TravelerRow(
                    icon: "figure.child",
                    label: "Children",
                    subtitle: "Under 12",
                    count: $childCount,
                    minimum: 0
                )
            }
            .padding(.horizontal, 20)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TravelerRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    @Binding var count: Int
    let minimum: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.body)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 20) {
                Button {
                    if count > minimum { count -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(count > minimum ? .green : .secondary)
                }
                .disabled(count <= minimum)

                Text("\(count)")
                    .font(.title3.weight(.bold))
                    .frame(width: 28, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.2), value: count)

                Button {
                    if count < 20 { count += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 14)
    }
}

private struct VisaStatusBadge: View {
    let status: VisaStatus

    var body: some View {
        Label(statusText, systemImage: statusIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.12), in: Capsule())
    }

    private var statusText: String {
        switch status {
        case .visaFree: return "Visa-free"
        case .visaOnArrival: return "Visa on arrival"
        case .eVisa: return "e-Visa"
        case .visaRequired: return "Visa required"
        case .unknown: return "Visa unknown"
        }
    }

    private var statusIcon: String {
        switch status {
        case .visaFree: return "checkmark.seal.fill"
        case .visaOnArrival, .eVisa: return "doc.badge.arrow.up"
        case .visaRequired: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .visaFree: return .green
        case .visaOnArrival, .eVisa: return .orange
        case .visaRequired: return .red
        case .unknown: return .gray
        }
    }
}

private extension String {
    var shortFormatted: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        guard let date = fmt.date(from: self) else { return self }
        let out = DateFormatter()
        out.dateStyle = .short
        out.timeStyle = .none
        return out.string(from: date)
    }
}

// MARK: - Mode picker

struct TripModePicker: View {
    @Bindable var viewModel: SelectedTripViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.trip.availableModes) { mode in
                ModeTab(
                    mode: mode,
                    isSelected: viewModel.selectedMode == mode,
                    variant: viewModel.trip.modeVariants[mode]
                )
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.25)) {
                        viewModel.selectedMode = mode
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(3)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
    }
}

private struct ModeTab: View {
    let mode: TripMode
    let isSelected: Bool
    let variant: ModeVariant?

    var body: some View {
        VStack(spacing: 2) {
            Text(mode.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)

            if let variant {
                Text("\(Int(variant.totalCost / 1_000))k")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary.opacity(0.55))
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.green : Color.clear, in: RoundedRectangle(cornerRadius: 10))
        .animation(.smooth(duration: 0.2), value: isSelected)
    }
}

// MARK: - Previews

struct TripHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TripHeaderView(viewModel: .preview)
            TripModePicker(viewModel: .preview)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
