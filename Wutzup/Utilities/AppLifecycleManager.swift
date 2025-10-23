//
//  AppLifecycleManager.swift
//  Wutzup
//
//  Manages app lifecycle transitions for optimal battery usage and data sync
//  - Pauses/resumes Firestore listeners on background/foreground
//  - Updates presence status
//  - Syncs missed messages
//  - Handles background tasks
//

import Foundation
import UIKit
import Combine
import BackgroundTasks

/// Manages app lifecycle events and coordinates services accordingly
@MainActor
class AppLifecycleManager: ObservableObject {
    /// Shared singleton instance
    static let shared = AppLifecycleManager()
    
    /// Current app lifecycle state
    @Published private(set) var lifecycleState: LifecycleState = .active
    
    /// Time when app was last backgrounded
    @Published private(set) var lastBackgroundTime: Date?
    
    /// Time when app was last foregrounded
    @Published private(set) var lastForegroundTime: Date?
    
    /// Whether listeners are currently active
    @Published private(set) var listenersActive: Bool = true
    
    /// Background task identifier for message sync
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    
    /// Observers for lifecycle notifications
    private var cancellables = Set<AnyCancellable>()
    
    /// Callback for when app enters foreground (for syncing)
    var onForeground: ((TimeInterval?) -> Void)?
    
    /// Callback for when app enters background (for cleanup)
    var onBackground: (() -> Void)?
    
    /// Callback for pausing listeners
    var onPauseListeners: (() -> Void)?
    
    /// Callback for resuming listeners
    var onResumeListeners: (() -> Void)?
    
    enum LifecycleState: String {
        case active = "Active"
        case inactive = "Inactive"
        case background = "Background"
    }
    
    private init() {
        setupLifecycleObservers()
        registerBackgroundTasks()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Lifecycle Observers
    
    private func setupLifecycleObservers() {
        
        // Will Resign Active (transitioning from active to inactive/background)
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleWillResignActive()
                }
            }
            .store(in: &cancellables)
        
        // Did Enter Background (fully backgrounded)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleDidEnterBackground()
                }
            }
            .store(in: &cancellables)
        
        // Will Enter Foreground (about to become active)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleWillEnterForeground()
                }
            }
            .store(in: &cancellables)
        
        // Did Become Active (fully active)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleDidBecomeActive()
                }
            }
            .store(in: &cancellables)
        
        // Will Terminate (app is shutting down)
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleWillTerminate()
                }
            }
            .store(in: &cancellables)
        
    }
    
    // MARK: - Lifecycle Event Handlers
    
    private func handleWillResignActive() async {
        lifecycleState = .inactive
    }
    
    private func handleDidEnterBackground() async {
        lifecycleState = .background
        lastBackgroundTime = Date()
        
        // Start background task to complete any pending operations
        backgroundTaskId = await UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Pause Firestore listeners to save battery
        await pauseListeners()
        
        // Notify callback
        onBackground?()
        
        
        // End background task after a short delay to allow any pending operations to complete
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            endBackgroundTask()
        }
    }
    
    private func handleWillEnterForeground() async {
        lifecycleState = .inactive
        
        // Calculate background duration
        let backgroundDuration = lastBackgroundTime.map { Date().timeIntervalSince($0) }
        
        if let duration = backgroundDuration {
        }
        
        // Resume listeners
        await resumeListeners()
        
        // Notify callback with background duration for potential sync
        onForeground?(backgroundDuration)
    }
    
    private func handleDidBecomeActive() async {
        lifecycleState = .active
        lastForegroundTime = Date()
        
        // End any lingering background tasks
        endBackgroundTask()
        
    }
    
    private func handleWillTerminate() async {
        
        // Ensure listeners are cleaned up
        await pauseListeners()
        
        // End any background tasks
        endBackgroundTask()
    }
    
    // MARK: - Listener Management
    
    private func pauseListeners() async {
        guard listenersActive else {
            return
        }
        
        listenersActive = false
        
        // Notify callback to pause listeners
        onPauseListeners?()
        
    }
    
    private func resumeListeners() async {
        guard !listenersActive else {
            return
        }
        
        listenersActive = true
        
        // Notify callback to resume listeners
        onResumeListeners?()
        
    }
    
    // MARK: - Background Task Management
    
    private func endBackgroundTask() {
        guard backgroundTaskId != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskId)
        backgroundTaskId = .invalid
    }
    
    private func registerBackgroundTasks() {
        // Register background refresh task for periodic syncing
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.wutzup.refresh",
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }
        
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        
        // Schedule next refresh
        scheduleBackgroundRefresh()
        
        // Perform sync (callback should be set by AppState)
        // This allows periodic syncing even when app is suspended
        
        // Complete the task
        task.setTaskCompleted(success: true)
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.wutzup.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch let error as NSError {
            // BGTaskSchedulerErrorCodeUnavailable (Code 1) is expected in:
            // - Simulator (background tasks don't work)
            // - Debugging (Xcode prevents scheduling)
            // - Background App Refresh disabled in Settings
            if error.domain == "BGTaskSchedulerErrorDomain" && error.code == 1 {
            } else {
            }
        }
    }
    
    // MARK: - Public Utilities
    
    /// Check if app has been in background long enough to require sync
    func shouldSyncMissedMessages(threshold: TimeInterval = 30) -> Bool {
        guard let backgroundDuration = lastBackgroundTime.map({ Date().timeIntervalSince($0) }) else {
            return false
        }
        return backgroundDuration > threshold
    }
    
    /// Get current background duration (if backgrounded)
    var backgroundDuration: TimeInterval? {
        guard lifecycleState == .background,
              let lastBackgroundTime = lastBackgroundTime else {
            return nil
        }
        return Date().timeIntervalSince(lastBackgroundTime)
    }
    
    /// Check if app is effectively in the background
    var isInBackground: Bool {
        return lifecycleState == .background || lifecycleState == .inactive
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appDidEnterForeground = Notification.Name("appDidEnterForeground")
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let listenersDidPause = Notification.Name("listenersDidPause")
    static let listenersDidResume = Notification.Name("listenersDidResume")
}

