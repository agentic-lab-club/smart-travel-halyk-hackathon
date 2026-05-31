import SwiftUI

struct AddOnCard: View {
    let addOn: TripAddOn
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? addOn.categoryColor : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 42, height: 42)
                    Image(systemName: addOn.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : addOn.categoryColor)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(addOn.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let badge = addOn.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(addOn.categoryColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(addOn.categoryColor.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(addOn.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(addOn.price.displayString)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? addOn.categoryColor : .primary)
                        .padding(.top, 2)
                }

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? addOn.categoryColor : Color(.tertiarySystemFill))
                    .symbolEffect(.bounce, value: isSelected)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? addOn.categoryColor.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .animation(.smooth(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
