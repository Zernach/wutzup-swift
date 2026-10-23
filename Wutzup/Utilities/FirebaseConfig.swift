import Foundation
import FirebaseAuth

/// Firebase supplies identity only. Persistence and API traffic belong to Archlife.
enum FirebaseConfig {
    static func configureEmulators() {
        #if DEBUG
        if let address = ProcessInfo.processInfo.environment["FIREBASE_AUTH_EMULATOR_HOST"],
           let url = URL(string: "http://" + address), let host = url.host {
            Auth.auth().useEmulator(withHost: host, port: url.port ?? 9099)
        }
        #endif
    }
}
