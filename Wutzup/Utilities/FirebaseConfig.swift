//
//  FirebaseConfig.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

enum FirebaseConfig {
    private enum EmulatorFlag {
        static let masterToggle = "USE_FIREBASE_EMULATORS"
        static let firestore = "FIRESTORE_EMULATOR_HOST"
        static let auth = "FIREBASE_AUTH_EMULATOR_HOST"
        static let storage = "FIREBASE_STORAGE_EMULATOR_HOST"
    }
    
    static let isProductionBuild: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()
    
    private static var useEmulators: Bool {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        let arguments = Set(processInfo.arguments)
        let environment = processInfo.environment
        
        if arguments.contains("--disable-firebase-emulators") { return false }
        if arguments.contains("--use-firebase-emulators") { return true }
        
        if let explicitFlag = environment[EmulatorFlag.masterToggle] {
            return explicitFlag != "0" && explicitFlag.lowercased() != "false"
        }
        
        return environment[EmulatorFlag.firestore] != nil ||
               environment[EmulatorFlag.auth] != nil ||
               environment[EmulatorFlag.storage] != nil
        #else
        return false
        #endif
    }
    
    private static func firestoreEndpoint() -> String? {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let explicitHost = environment[EmulatorFlag.firestore], !explicitHost.isEmpty {
            return explicitHost
        }
        if useEmulators {
            return "localhost:8080"
        }
        #endif
        return nil
    }
    
    private static func authEndpoint() -> (host: String, port: Int)? {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let explicit = environment[EmulatorFlag.auth], !explicit.isEmpty {
            return splitHostPort(explicit, defaultPort: 9099)
        }
        if useEmulators {
            return ("localhost", 9099)
        }
        #endif
        return nil
    }
    
    private static func storageEndpoint() -> (host: String, port: Int)? {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let explicit = environment[EmulatorFlag.storage], !explicit.isEmpty {
            return splitHostPort(explicit, defaultPort: 9199)
        }
        if useEmulators {
            return ("localhost", 9199)
        }
        #endif
        return nil
    }
    
    // Configure Firestore settings (must be called BEFORE accessing Firestore)
    static func configureFirestore() {
        let settings = FirestoreSettings()
        let emulatorHost = firestoreEndpoint()
        
        if let emulatorHost {
            print("⚠️ Configuring Firestore for Emulator @ \(emulatorHost)")
            settings.host = emulatorHost
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
        } else {
            settings.cacheSettings = PersistentCacheSettings()
        }
        
        Firestore.firestore().settings = settings
    }
    
    // Configure emulators for debug builds
    static func configureEmulators() {
        guard useEmulators else {
            #if DEBUG
            print("ℹ️ Firebase emulators disabled for this run.")
            #endif
            return
        }
        
        if let authConfig = authEndpoint() {
            Auth.auth().useEmulator(withHost: authConfig.host, port: authConfig.port)
        }
        
        if let storageConfig = storageEndpoint() {
            Storage.storage().useEmulator(withHost: storageConfig.host, port: storageConfig.port)
        }
        
        print("✅ Firebase Emulators configured")
    }
    
    private static func splitHostPort(_ address: String, defaultPort: Int) -> (host: String, port: Int) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.hasPrefix("["), let closingBracket = trimmed.firstIndex(of: "]") {
            let host = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closingBracket])
            let remainder = trimmed[trimmed.index(after: closingBracket)...]
            if remainder.hasPrefix(":"), let port = Int(remainder.dropFirst()) {
                return (host, port)
            }
            return (host, defaultPort)
        }
        
        let colonCount = trimmed.filter { $0 == ":" }.count
        if colonCount == 1, let separator = trimmed.lastIndex(of: ":") {
            let portCandidate = trimmed[trimmed.index(after: separator)...]
            if let port = Int(portCandidate) {
                let host = String(trimmed[..<separator])
                return (host, port)
            }
        }
        
        return (trimmed, defaultPort)
    }
}
