//
//  AppSettings.swift
//  CoconutDoctor
//
//  UserDefaults-backed application settings and security preferences.
//  Strictly stores toggle flags only — no credentials or biometric data are stored.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppSettings: ObservableObject, @unchecked Sendable {
    private enum Keys {
        static let isAppLockEnabled = "CoconutDoctor.Settings.isAppLockEnabled"
        static let isAccountLockEnabled = "CoconutDoctor.Settings.isAccountLockEnabled"
        static let selectedLanguage = "CoconutDoctor.Settings.selectedLanguage"
        static let hasCompletedOnboarding = "CoconutDoctor.Settings.hasCompletedOnboarding"
        static let isTreatmentRemindersEnabled = "CoconutDoctor.Settings.isTreatmentRemindersEnabled"
        static let isWeeklyInspectionEnabled = "CoconutDoctor.Settings.isWeeklyInspectionEnabled"
        static let isOutbreakAlertsEnabled = "CoconutDoctor.Settings.isOutbreakAlertsEnabled"
        static let isSyncNotificationsEnabled = "CoconutDoctor.Settings.isSyncNotificationsEnabled"
    }
    
    private let defaults: UserDefaults
    
    @Published public var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    @Published public var isAppLockEnabled: Bool {
        didSet {
            defaults.set(isAppLockEnabled, forKey: Keys.isAppLockEnabled)
        }
    }
    
    @Published public var isAccountLockEnabled: Bool {
        didSet {
            defaults.set(isAccountLockEnabled, forKey: Keys.isAccountLockEnabled)
        }
    }
    
    @Published public var isTreatmentRemindersEnabled: Bool {
        didSet {
            defaults.set(isTreatmentRemindersEnabled, forKey: Keys.isTreatmentRemindersEnabled)
        }
    }
    
    @Published public var isWeeklyInspectionEnabled: Bool {
        didSet {
            defaults.set(isWeeklyInspectionEnabled, forKey: Keys.isWeeklyInspectionEnabled)
        }
    }
    
    @Published public var isOutbreakAlertsEnabled: Bool {
        didSet {
            defaults.set(isOutbreakAlertsEnabled, forKey: Keys.isOutbreakAlertsEnabled)
        }
    }
    
    @Published public var isSyncNotificationsEnabled: Bool {
        didSet {
            defaults.set(isSyncNotificationsEnabled, forKey: Keys.isSyncNotificationsEnabled)
        }
    }
    
    @Published public var selectedLanguage: AppLanguage {
        didSet {
            defaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
        }
    }
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isAppLockEnabled = defaults.bool(forKey: Keys.isAppLockEnabled)
        self.isAccountLockEnabled = defaults.bool(forKey: Keys.isAccountLockEnabled)
        self.isTreatmentRemindersEnabled = defaults.object(forKey: Keys.isTreatmentRemindersEnabled) == nil ? true : defaults.bool(forKey: Keys.isTreatmentRemindersEnabled)
        self.isWeeklyInspectionEnabled = defaults.object(forKey: Keys.isWeeklyInspectionEnabled) == nil ? true : defaults.bool(forKey: Keys.isWeeklyInspectionEnabled)
        self.isOutbreakAlertsEnabled = defaults.object(forKey: Keys.isOutbreakAlertsEnabled) == nil ? true : defaults.bool(forKey: Keys.isOutbreakAlertsEnabled)
        self.isSyncNotificationsEnabled = defaults.object(forKey: Keys.isSyncNotificationsEnabled) == nil ? true : defaults.bool(forKey: Keys.isSyncNotificationsEnabled)
        
        if ProcessInfo.processInfo.arguments.contains("-reset-onboarding") || ProcessInfo.processInfo.arguments.contains("-onboarding") {
            self.hasCompletedOnboarding = false
        } else {
            self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        
        if let raw = defaults.string(forKey: Keys.selectedLanguage), let lang = AppLanguage(rawValue: raw) {
            self.selectedLanguage = lang
        } else {
            self.selectedLanguage = AppLanguage.currentDeviceLanguage
        }
    }
}
