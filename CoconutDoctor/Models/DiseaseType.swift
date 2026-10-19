//
//  DiseaseType.swift
//  CoconutDoctor
//
//  Coconut leaf disease classification types matching model output order.
//

import SwiftUI

public enum DiseaseType: String, CaseIterable, Identifiable, Codable, Sendable {
    // EXACT MODEL OUTPUT ORDER (index 0 to 4):
    case budRot = "BudRot"
    case greyLeafSpot = "GreyLeafSpot"
    case leafRot = "LeafRot"
    case stemBleeding = "StemBleeding"
    case healthy = "Healthy"
    
    public var id: String { rawValue }
    
    /// User-friendly English display title
    public var displayName: String {
        switch self {
        case .budRot:
            return "Bud Rot"
        case .greyLeafSpot:
            return "Grey Leaf Spot"
        case .leafRot:
            return "Leaf Rot"
        case .stemBleeding:
            return "Stem Bleeding"
        case .healthy:
            return "Healthy Palm"
        }
    }
    
    /// Associated theme color
    public var themeColor: Color {
        switch self {
        case .budRot:
            return .diseaseBudRot
        case .greyLeafSpot:
            return .diseaseGreyLeafSpot
        case .leafRot:
            return .diseaseLeafRot
        case .stemBleeding:
            return .diseaseStemBleeding
        case .healthy:
            return .diseaseHealthy
        }
    }
    
    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .budRot:
            return "exclamationmark.triangle.fill"
        case .greyLeafSpot:
            return "circle.dotted"
        case .leafRot:
            return "waveform.path.ecg"
        case .stemBleeding:
            return "drop.fill"
        case .healthy:
            return "checkmark.seal.fill"
        }
    }
}
