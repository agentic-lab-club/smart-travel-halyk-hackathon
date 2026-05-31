import SwiftUI

struct FieldCard: View {
    let field: MissingField
    @Bindable var viewModel: EntryFlowViewModel

    private var isDateField: Bool { field.key == "start_date" || field.key == "end_date" }
    private var isStartDate: Bool { field.key == "start_date" }
    private var isEndDate: Bool { field.key == "end_date" }
    private var isBudget: Bool { field.key == "budget" }

    // ISO 8601 formatter for storage
    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var minimumStartDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    private var minimumEndDate: Date {
        let startRaw = viewModel.bindingValue(for: "start_date")
        let startDate = Self.isoFormatter.date(from: startRaw) ?? minimumStartDate
        return startDate < minimumStartDate ? minimumStartDate : startDate
    }

    private var dateRange: ClosedRange<Date> {
        if isStartDate {
            return minimumStartDate...Date.distantFuture
        }
        if isEndDate {
            return minimumEndDate...Date.distantFuture
        }
        return minimumStartDate...Date.distantFuture
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let raw = viewModel.bindingValue(for: field.key)
                let fallback = isStartDate ? minimumStartDate : minimumEndDate
                let parsed = Self.isoFormatter.date(from: raw) ?? fallback
                return parsed < fallback ? fallback : parsed
            },
            set: { date in
                let normalized = Self.isoFormatter.string(from: date)
                viewModel.setBindingValue(normalized, for: field.key)

                guard isStartDate else { return }
                let minEndDate = date < minimumStartDate ? minimumStartDate : date
                let currentEndRaw = viewModel.bindingValue(for: "end_date")
                if let currentEnd = Self.isoFormatter.date(from: currentEndRaw), currentEnd < minEndDate {
                    viewModel.setBindingValue(Self.isoFormatter.string(from: minEndDate), for: "end_date")
                }
            }
        )
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.bindingValue(for: field.key) },
            set: { viewModel.setBindingValue($0, for: field.key) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(field.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isDateField {
                DatePicker(
                    "",
                    selection: dateBinding,
                    in: dateRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(planningColors.accent)
                .colorScheme(.dark)
            } else {
                HStack(spacing: 8) {
                    TextField(field.prompt, text: textBinding)
                        .keyboardType(isBudget ? .numberPad : .default)
                        .textInputAutocapitalization(isBudget ? .never : .words)
                        .font(.body)
                        .foregroundStyle(.white)
                        .tint(planningColors.accent)

                    if isBudget {
                        Text("KZT")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(planningColors.card, in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            if isDateField {
                let fallback = isStartDate ? minimumStartDate : minimumEndDate
                let current = viewModel.bindingValue(for: field.key)
                let parsed = Self.isoFormatter.date(from: current) ?? fallback
                let clamped = parsed < fallback ? fallback : parsed
                viewModel.setBindingValue(Self.isoFormatter.string(from: clamped), for: field.key)

                if isStartDate {
                    let endRaw = viewModel.bindingValue(for: "end_date")
                    if let endDate = Self.isoFormatter.date(from: endRaw), endDate < clamped {
                        viewModel.setBindingValue(Self.isoFormatter.string(from: clamped), for: "end_date")
                    }
                }
            } else if isBudget {
                let current = viewModel.bindingValue(for: field.key)
                if let value = Int(current), value <= 0 {
                    viewModel.setBindingValue("", for: field.key)
                }
            }
        }
    }
}
