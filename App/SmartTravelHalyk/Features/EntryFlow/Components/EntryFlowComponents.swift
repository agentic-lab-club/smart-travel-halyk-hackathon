import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 8))
    }
}

struct PriceBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 8))
    }
}

struct DestinationBadge: View {
    let countryCode: String

    var body: some View {
        Text(countryCode)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.green, in: .rect(cornerRadius: 8))
    }
}

struct FlowLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.green.opacity(0.12), in: .capsule)
            }
        }
    }
}

struct EntryFlowComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Ready trips",
                subtitle: "Personalized from profile, season, budget and cashback."
            )
            HStack {
                MetricPill(title: "People", value: "2")
                MetricPill(title: "Dates", value: "Jun - Sep")
            }
            HStack {
                PriceBlock(title: "Budget", value: "742 000 KZT")
                DestinationBadge(countryCode: "TR")
            }
            FlowLayout(items: ["Visa-free", "Direct flight", "Food match", "Cashback boost"])
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
