import SwiftUI

struct HotelDetailHeroSection: View {
    let full: HotelDetailsFull

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: full.mainImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Rectangle().fill(Color(.tertiarySystemGroupedBackground))
                        .overlay {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary.opacity(0.4))
                        }
                }
            }
            .frame(height: 240)
            .clipped()

            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .bottom,
                endPoint: .center
            )

            VStack(alignment: .leading, spacing: 4) {
                if let stars = full.stars {
                    HStack(spacing: 2) {
                        ForEach(0..<stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                Text(full.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                if let district = full.district {
                    Label(district, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(14)
        }
    }
}
