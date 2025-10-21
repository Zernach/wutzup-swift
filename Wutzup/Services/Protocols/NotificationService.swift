//
//  NotificationService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation

protocol NotificationService: AnyObject {
    func requestPermission() async throws -> Bool
    func registerDeviceToken(_ token: Data) async throws
    func updateFCMToken(userId: String, token: String) async throws
}

