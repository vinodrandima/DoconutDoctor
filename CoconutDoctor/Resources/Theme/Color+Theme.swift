//
//  Color+Theme.swift
//  CoconutDoctor
//
//  Shared UI Color Theme for CoconutDoctor.
//

import SwiftUI

extension Color {
    // MARK: - App Branding
    public static let appAccent = Color("AccentColor")
    
    // MARK: - Disease Classification Colors
    public static let diseaseBudRot = Color("BudRotColor")
    public static let diseaseGreyLeafSpot = Color("GreyLeafSpotColor")
    public static let diseaseLeafRot = Color("LeafRotColor")
    public static let diseaseStemBleeding = Color("StemBleedingColor")
    public static let diseaseHealthy = Color("HealthyColor")
    
    /// Map disease name to its assigned theme color
    public static func color(forDisease name: String) -> Color {
        switch name.lowercased() {
        case "budrot", "bud rot":
            return .diseaseBudRot
        case "greyleafspot", "grey leaf spot", "gray leaf spot":
            return .diseaseGreyLeafSpot
        case "leafrot", "leaf rot":
            return .diseaseLeafRot
        case "stembleeding", "stem bleeding":
            return .diseaseStemBleeding
        case "healthy":
            return .diseaseHealthy
        default:
            return .secondary
        }
    }
}
