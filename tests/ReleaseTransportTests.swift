import Foundation

@main
struct ReleaseTransportTests {
    static func main() throws {
        for host in ["api.archlife.org", "api-dev.archlife.org"] {
            let request = URLRequest(url: URL(string: "https://" + host + "/api/wutzup/data/messages")!)
            let authorized = try WutzupRequestTransport.prepare(request, token: "synthetic-token")
            precondition(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-token")
        }
        for origin in [
            "https://api-dev.archlife", "https://api-dev.archlife:18443", "http://127.0.0.1:18443",
            "https://localhost:18443", "https://api.archlife.org:18443",
        ] {
            do {
                _ = try WutzupRequestTransport.prepare(
                    URLRequest(url: URL(string: origin + "/api/wutzup/data/messages")!),
                    token: "synthetic-token")
                fatalError("Release accepted an emulator or nonstandard API origin")
            } catch {}
        }
        print("Release transport excludes all emulator origins")
    }
}
