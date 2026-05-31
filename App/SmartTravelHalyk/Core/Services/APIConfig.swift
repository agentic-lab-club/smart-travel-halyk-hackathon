import Foundation

/// Central API configuration.
///
/// - For iOS Simulator: 127.0.0.1 resolves to the host machine's loopback,
///   so it reaches backends running on your Mac.
/// - For a physical device: replace with your Mac's local network IP (e.g. 192.168.1.x).
/// - Go backend (trips, recommendations): port 8080
/// - Python agent (itinerary chat): port 8000
enum APIConfig {
#if targetEnvironment(simulator)
    private static let host = "127.0.0.1"
#else
    private static let host = "172.20.10.2"
#endif

    static let baseURL = URL(string: "http://\(host):8080/api/v1/")!
    static let agentURL = URL(string: "http://\(host):8000/agent")!
    static let agentBaseURL = URL(string: "http://\(host):8000/")!
}
