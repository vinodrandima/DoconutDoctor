//
//  NotificationService.swift
//  CoconutDoctor
//
//  Local notification service for CoconutDoctor managing disease treatment follow-ups,
//  weekly grove inspections, and contagious outbreak alerts.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
public final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    public override init() {
        super.init()
        center.delegate = self
        Task {
            await checkStatus()
        }
    }
    
    public func checkStatus() async {
        let settings = await center.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
    }
    
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkStatus()
            return granted
        } catch {
            print("[NotificationService] Authorization request error: \(error.localizedDescription)")
            await checkStatus()
            return false
        }
    }
    
    // MARK: - Treatment Follow-up Reminders
    
    /// Schedules a follow-up reminder after given days (default 7 days for Bud Rot / Leaf Rot CRI protocols).
    @discardableResult
    public func scheduleTreatmentReminder(disease: DiseaseType, afterDays: Int = 7, scanId: String? = nil) async -> Bool {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return false }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 Treatment Follow-Up: \(disease.displayName)"
        
        switch disease {
        case .budRot:
            content.body = "It has been \(afterDays) days since Bud Rot was diagnosed. Inspect palm heart/spear leaf to verify if fungal rot halted. Reapply copper fungicide / Bordeaux paste if necessary."
        case .leafRot:
            content.body = "7-Day Leaf Rot check: Examine infected fronds to confirm necrotic spots have dried out and not spread to neighboring leaves."
        case .stemBleeding:
            content.body = "Stem Bleeding check: Inspect trunk lesions to confirm tar sealing is intact."
        case .greyLeafSpot:
            content.body = "Grey Leaf Spot check: Verify fungal spots have stabilized."
        case .healthy:
            content.body = "Routine palm follow-up check."
        }
        
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "treatment_reminder", "disease": disease.rawValue]
        
        // Use specified days (for testing/immediate simulation: 5 seconds if afterDays <= 0)
        let timeInterval: TimeInterval = afterDays > 0 ? Double(afterDays * 86400) : 5
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let identifier = "CoconutDoctor.Treatment.\(scanId ?? UUID().uuidString)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            print("[NotificationService] Failed to schedule reminder: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Weekly Farm Inspection
    
    /// Schedules a weekly grove inspection reminder (Sunday at 8:00 AM by default)
    public func scheduleWeeklyInspection(weekday: Int = 1, hour: Int = 8, minute: Int = 0) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🌴 Weekly Plantation Inspection"
        content.body = "Good morning, Farmer! Time for your weekly coconut grove inspection. Check spear leaves and fresh fronds to catch early infections."
        content.sound = .default
        content.userInfo = ["type": "weekly_inspection"]
        
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "CoconutDoctor.WeeklyInspection", content: content, trigger: trigger)
        
        try? await center.add(request)
    }
    
    public func cancelWeeklyInspection() {
        center.removePendingNotificationRequests(withIdentifiers: ["CoconutDoctor.WeeklyInspection"])
    }
    
    // MARK: - Outbreak & Cluster Alert
    
    public func sendOutbreakAlert(disease: DiseaseType, count: Int) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ High-Risk Outbreak Alert"
        content.body = "\(count) active cases of \(disease.displayName) detected in your grove! Inspect adjacent palms and apply CRI-recommended preventive measures immediately."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "outbreak_alert", "disease": disease.rawValue]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "CoconutDoctor.Outbreak.\(UUID().uuidString)", content: content, trigger: trigger)
        
        try? await center.add(request)
    }
    
    // MARK: - Cloud Sync Notification
    
    public func sendSyncSuccessNotification(count: Int) async {
        guard isAuthorized && count > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "☁️ Cloud Backup Complete"
        content.body = "\(count) offline field scan \(count == 1 ? "record" : "records") safely backed up to Firebase Firestore."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "CoconutDoctor.Sync.\(UUID().uuidString)", content: content, trigger: trigger)
        
        try? await center.add(request)
    }
    
    // MARK: - Instant Test Notification
    
    @discardableResult
    public func sendTestNotification() async -> Bool {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return false }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🌴 CoconutDoctor Alert Active"
        content.body = "Notifications are enabled! You will receive treatment follow-ups, outbreak alerts, and weekly inspection reminders."
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request = UNNotificationRequest(identifier: "CoconutDoctor.Test.\(UUID().uuidString)", content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            return true
        } catch {
            print("[NotificationService] Test notification failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Display banner while app is in foreground
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge, .list]
    }
    
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Reserved for future deep linking to specific scans
    }
}
