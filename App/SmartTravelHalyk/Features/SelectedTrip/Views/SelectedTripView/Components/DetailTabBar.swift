import SwiftUI

struct DetailTabBar: View {
    @Binding var selected: DetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.smooth(duration: 0.25)) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .medium))
                        Text(tab.title)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selected == tab ? .green : .secondary)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(selected == tab ? Color.green : Color.clear)
                            .frame(height: 2)
                    }
                    .animation(.smooth(duration: 0.25), value: selected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
