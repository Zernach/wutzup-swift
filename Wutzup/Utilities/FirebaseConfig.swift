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
    
    // Configure Firestore settings
    static func configureFirestore() {
        let settings = FirestoreSettings()
        
        // Enable offline persistence
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        Firestore.firestore().settings = settings
    }
    
    // Configure emulators for debug builds
    static func configureEmulators() {
        #if DEBUG
        print("⚠️ Configuring Firebase Emulators")
        
        // Firestore emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        // Auth emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        
        // Storage emulator
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        
        print("✅ Firebase Emulators configured")
        #endif
    }
}

