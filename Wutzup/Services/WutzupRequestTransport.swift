import Foundation

final class WutzupSessionDelegate: NSObject, URLSessionTaskDelegate {
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                               willPerformHTTPRedirection response: HTTPURLResponse,
                               newRequest request: URLRequest,
                               completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

enum WutzupRequestTransport {
    static func prepare(_ original: URLRequest, token: String) throws -> URLRequest {
        var allowedHosts = ["api.archlife.org", "api-dev.archlife.org"]
        #if DEBUG
        allowedHosts.append("api-dev.archlife")
        #endif
        guard let url = original.url, url.scheme == "https",
              let host = url.host, allowedHosts.contains(host),
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.port == nil || url.port == 443 || (host == "api-dev.archlife" && url.port == 18443),
              url.standardized.path.hasPrefix("/api/wutzup/"),
              !token.isEmpty, !token.contains(where: { $0.isWhitespace }) else {
            throw NSError(domain: "WutzupAPI", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid authenticated API request."])
        }
        var request = original
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(request.value(forHTTPHeaderField: "Idempotency-Key") ?? UUID().uuidString,
                         forHTTPHeaderField: "Idempotency-Key")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        request.timeoutInterval = 180
        return request
    }
}
