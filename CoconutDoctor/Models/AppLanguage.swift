//
//  AppLanguage.swift
//  CoconutDoctor
//
//  Supported application languages for Sri Lankan farmers.
//

import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case sinhala = "si"
    case tamil = "ta"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english:
            return "English"
        case .sinhala:
            return "සිංහල"
        case .tamil:
            return "தமிழ்"
        }
    }
    
    /// Detects best matching language from current iOS device locale
    public static var currentDeviceLanguage: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("si") {
            return .sinhala
        } else if preferred.hasPrefix("ta") {
            return .tamil
        } else {
            return .english
        }
    }
}
