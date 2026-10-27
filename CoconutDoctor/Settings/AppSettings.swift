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
    }
    
    private let defaults: UserDefaults
    
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
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isAppLockEnabled = defaults.bool(forKey: Keys.isAppLockEnabled)
        self.isAccountLockEnabled = defaults.bool(forKey: Keys.isAccountLockEnabled)
    }
}
