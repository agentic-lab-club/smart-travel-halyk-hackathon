import Foundation
import UIKit

// MARK: - Models

private struct WikiSummary: Decodable {
    let thumbnail: WikiThumbnail?
}

private struct WikiThumbnail: Decodable {
    let source: String
}

// MARK: - Service

actor UnsplashService {

    static let shared = UnsplashService()

    private var urlCache: [String: URL] = [:]
    private var imageCache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }

    func fetchPhotoURL(query: String) async throws -> URL {
        let cacheKey = query.lowercased()
        if let cached = urlCache[cacheKey] { return cached }

        // Wikipedia REST API — no auth required
        let slug = query.replacingOccurrences(of: " ", with: "_")
        guard let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        else { throw APIError.invalidURL }

        print("[WikiService] requesting: \(url)")
        let (data, response) = try await session.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[WikiService] status: \(statusCode), bytes: \(data.count)")
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        let summary = try JSONDecoder().decode(WikiSummary.self, from: data)
        print("[WikiService] thumbnail source: \(summary.thumbnail?.source ?? "nil")")
        guard let source = summary.thumbnail?.source,
              let photoURL = URL(string: source)
        else { throw APIError.emptyResponse(200) }

        urlCache[cacheKey] = photoURL
        return photoURL
    }

    func fetchImage(url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString
        if let cached = imageCache.object(forKey: key) { return cached }

        let (data, _) = try await session.data(from: url)
        guard let image = UIImage(data: data) else { throw APIError.invalidResponse }

        imageCache.setObject(image, forKey: key)
        return image
    }
}
