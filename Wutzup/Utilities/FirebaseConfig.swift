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
    static let isProductionBuild: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()
    
    // Configure Firestore settings (must be called BEFORE accessing Firestore)
    static func configureFirestore() {
        let settings = FirestoreSettings()
        
        #if DEBUG
        // Debug mode: Use emulator with memory cache
        print("⚠️ Configuring Firestore for Emulator")
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        #else
        // Production mode: Enable offline persistence with unlimited cache
        settings.cacheSettings = PersistentCacheSettings()
        #endif
        
        Firestore.firestore().settings = settings
    }
    
    // Configure emulators for debug builds
    static func configureEmulators() {
        #if DEBUG
        print("⚠️ Configuring Firebase Emulators")
        
        // Auth emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        
        // Storage emulator
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        
        print("✅ Firebase Emulators configured")
        #endif
    }
}

