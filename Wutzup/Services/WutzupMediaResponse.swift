import Foundation

nonisolated enum WutzupMediaResponse {
    static func mayDownload(_ url: URL) -> Bool {
        url.scheme == "https" && url.user == nil && url.password == nil &&
            !["firebasestorage.googleapis.com", "storage.googleapis.com"].contains(url.host ?? "")
    }
    static func isImage(_ data: Data) -> Bool {
        guard !data.isEmpty, data.count <= 10 * 1024 * 1024 else { return false }
        return data.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]) ||
            data.starts(with: [255, 216, 255]) || data.starts(with: Data("GIF87a".utf8)) ||
            data.starts(with: Data("GIF89a".utf8)) ||
            (data.prefix(4) == Data("RIFF".utf8) && data.dropFirst(8).prefix(4) == Data("WEBP".utf8))
    }
    static func validate(_ data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              ["image/png", "image/jpeg", "image/gif", "image/webp"].contains(http.mimeType ?? ""), isImage(data) else {
            throw URLError(.badServerResponse)
        }
    }
}
