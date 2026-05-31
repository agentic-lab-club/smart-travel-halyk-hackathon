import Foundation

/// Central API configuration.
///
/// - For iOS Simulator: 127.0.0.1 resolves to the host machine's loopback,
///   so it reaches a backend running on your Mac.
/// - For a physical device: replace with your Mac's local network IP (e.g. 192.168.1.x).
enum APIConfig {
    static let baseURL = URL(string: "http://127.0.0.1:8080/api/v1")!
}
