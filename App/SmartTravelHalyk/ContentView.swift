import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Smart Travel")
                        .font(.largeTitle.bold())

                    Text("Halyk hackathon iOS starter app")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Travel")
        }
    }
}

#Preview {
    ContentView()
}
