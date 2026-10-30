//
//  DiseaseModelTests.swift
//  CoconutDoctorTests
//
//  Unit tests for coconut leaf disease taxonomy, display metadata,
//  and agronomic treatment knowledge base using Swift Testing.
//

import Testing
import Foundation
@testable import ios_coco

@Suite("Disease Model & Taxonomy Tests")
struct DiseaseModelTests {
    
    @Test("All model disease types map to expected raw values and IDs")
    func testDiseaseRawValues() {
        let expectedCases: [DiseaseType: String] = [
            .budRot: "BudRot",
            .greyLeafSpot: "GreyLeafSpot",
            .leafRot: "LeafRot",
            .stemBleeding: "StemBleeding",
            .healthy: "Healthy"
        ]
        
        #expect(DiseaseType.allCases.count == 5, "Model must strictly support 5 classification classes.")
        
        for (disease, rawVal) in expectedCases {
            #expect(disease.rawValue == rawVal)
            #expect(disease.id == rawVal)
        }
    }
    
    @Test("Every disease type has a user-friendly display name")
    func testDisplayNames() {
        #expect(DiseaseType.budRot.displayName == "Bud Rot")
        #expect(DiseaseType.greyLeafSpot.displayName == "Grey Leaf Spot")
        #expect(DiseaseType.leafRot.displayName == "Leaf Rot")
        #expect(DiseaseType.stemBleeding.displayName == "Stem Bleeding")
        #expect(DiseaseType.healthy.displayName == "Healthy Palm")
    }
    
    @Test("Every disease has a non-empty SF Symbol icon defined")
    func testIconNames() {
        for disease in DiseaseType.allCases {
            #expect(!disease.iconName.isEmpty, "Icon name for \(disease.rawValue) must not be empty.")
        }
    }
    
    @Test("Edge Case: Unknown raw value falls back safely to healthy palm in ScanRecord")
    func testUnknownRawValueFallback() {
        let invalidRecord = ScanRecord(
            diseaseLabel: "NonExistentUnknownDisease123",
            confidence: 0.95
        )
        #expect(invalidRecord.disease == .healthy, "Unknown disease labels should gracefully fallback to healthy.")
    }
}
