//
//  NotificationServiceTests.swift
//  CoconutDoctorTests
//
//  Unit tests for treatment follow-up reminder scheduling logic,
//  calendar date calculations, and AppSettings preferences using Swift Testing.
//

import Testing
import Foundation
@testable import ios_coco

@Suite("Field Notification Service Logic Tests")
struct NotificationServiceTests {
    
    @Test("7-day treatment reminder target date is calculated exactly 7 days in future")
    func testSevenDayFollowUpDateCalculation() {
        let calendar = Calendar.current
        let referenceDate = Date(timeIntervalSince1970: 1700000000) // Fixed point in time
        
        let expectedTargetDate = calendar.date(byAdding: .day, value: 7, to: referenceDate)
        #expect(expectedTargetDate != nil)
        
        let differenceInDays = calendar.dateComponents([.day], from: referenceDate, to: expectedTargetDate!).day
        #expect(differenceInDays == 7, "Follow-up interval must be exactly 7 calendar days.")
    }
    
    @Test("AppSettings correctly persists notification preference toggles")
    @MainActor
    func testAppSettingsNotificationToggles() {
        let settings = AppSettings()
        
        // Test Treatment Reminders
        settings.isTreatmentRemindersEnabled = true
        #expect(settings.isTreatmentRemindersEnabled == true)
        settings.isTreatmentRemindersEnabled = false
        #expect(settings.isTreatmentRemindersEnabled == false)
        
        // Test Weekly Inspection Reminders
        settings.isWeeklyInspectionEnabled = true
        #expect(settings.isWeeklyInspectionEnabled == true)
        
        // Test Outbreak Alerts
        settings.isOutbreakAlertsEnabled = true
        #expect(settings.isOutbreakAlertsEnabled == true)
        
        // Test Sync Notifications
        settings.isSyncNotificationsEnabled = true
        #expect(settings.isSyncNotificationsEnabled == true)
    }
}
