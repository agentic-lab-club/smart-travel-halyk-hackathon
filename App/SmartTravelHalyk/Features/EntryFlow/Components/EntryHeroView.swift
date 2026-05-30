import SwiftUI

struct EntryHeroView: View {
    let profile: UserProfileResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your next trip is already drafted")
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    Text(heroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.green, in: .rect(cornerRadius: 14))
            }

            HStack(spacing: 8) {
                Label("Visa and budget aware", systemImage: "checkmark.shield.fill")
                Label("Cashback ready", systemImage: "creditcard.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.green)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 8))
    }

    private var heroSubtitle: String {
        guard let profile else {
            return "Loading profile preferences and travel patterns."
        }
        return "From \(profile.homeCity), \(profile.travelProfile.budgetLevel.title) style, \(profile.currency.rawValue) budget."
    }
}

struct EntryHeroView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            EntryHeroView(profile: MockTravelData.userProfile)
            EntryHeroView(profile: nil)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
