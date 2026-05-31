import SwiftUI

struct UnsplashImageView<Placeholder: View>: View {
    let query: String
    let placeholder: () -> Placeholder

    private enum LoadState {
        case loading, loaded(UIImage), failed
    }

    @State private var state: LoadState = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                Color(white: 0.12)
                    .overlay { ProgressView().tint(.white) }
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            case .failed:
                placeholder()
            }
        }
        .task(id: query) {
            guard !query.isEmpty else { state = .failed; return }
            state = .loading
            print("[WikiImage] starting fetch for query: \(query)")
            do {
                let url = try await UnsplashService.shared.fetchPhotoURL(query: query)
                print("[WikiImage] photo URL: \(url)")
                let fetched = try await UnsplashService.shared.fetchImage(url: url)
                print("[WikiImage] image size: \(fetched.size)")
                withAnimation(.easeIn(duration: 0.3)) {
                    state = .loaded(fetched)
                }
            } catch {
                print("[WikiImage] error: \(error)")
                state = .failed
            }
        }
    }
}
