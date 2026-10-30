//
//  ScanRecordTests.swift
//  CoconutDoctorTests
//
//  Unit tests for the offline-first ScanRecord model, GPS geo-tagging,
//  and ResultView conversion using Swift Testing.
//

import Testing
import Foundation
import CoreLocation
@testable import ios_coco

@Suite("Offline-First ScanRecord Data Model Tests")
struct ScanRecordTests {
    
    @Test("ScanRecord initializes with valid defaults, UUID, and timestamp")
    func testInitializationDefaults() {
        let record = ScanRecord(
            disease: .budRot,
            confidence: 0.92
        )
        
        #expect(record.disease == .budRot)
        #expect(record.diseaseLabel == "BudRot")
        #expect(record.confidence == 0.92)
        #expect(record.latitude == nil)
        #expect(record.longitude == nil)
        #expect(record.coordinate == nil)
        #expect(record.isSynced == false)
        #expect(record.notes == nil)
    }
    
    @Test("GPS coordinates map correctly to CoreLocation 2D coordinate")
    func testCoordinateMapping() {
        let sriLankaLat = 7.2906
        let sriLankaLon = 80.6337
        
        let record = ScanRecord(
            disease: .stemBleeding,
            confidence: 0.89,
            latitude: sriLankaLat,
            longitude: sriLankaLon
        )
        
        #expect(record.coordinate != nil)
        #expect(abs((record.coordinate?.latitude ?? 0) - sriLankaLat) < 0.0001)
        #expect(abs((record.coordinate?.longitude ?? 0) - sriLankaLon) < 0.0001)
    }
    
    @Test("toClassificationResult generates valid classification result for history review")
    func testConversionToClassificationResult() {
        let record = ScanRecord(
            disease: .leafRot,
            confidence: 0.86
        )
        
        let result = record.toClassificationResult()
        #expect(result.disease == .leafRot)
        #expect(abs(Double(result.confidence) - 0.86) < 0.01)
        #expect(!result.topPredictions.isEmpty)
        #expect(result.topPredictions.first?.disease == .leafRot)
    }
    
    @Test("ScanRecord Codable JSON roundtrip preserves geo-tags, notes, and thumbnails")
    func testCodableRoundTrip() throws {
        let thumbnailData = "dummy-jpeg-data".data(using: .utf8)
        let original = ScanRecord(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 1700000000),
            diseaseLabel: "GreyLeafSpot",
            confidence: 0.91,
            latitude: 6.9271,
            longitude: 79.8612,
            imageThumbnail: thumbnailData,
            treatmentSnapshot: nil,
            notes: "Block C, Tree #44 frond showing brown lesions",
            imagePath: "/documents/scan_123.jpg",
            isSynced: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScanRecord.self, from: data)
        
        #expect(decoded.id == original.id)
        #expect(decoded.diseaseLabel == original.diseaseLabel)
        #expect(decoded.disease == .greyLeafSpot)
        #expect(abs(decoded.confidence - original.confidence) < 0.0001)
        #expect(decoded.latitude == original.latitude)
        #expect(decoded.longitude == original.longitude)
        #expect(decoded.notes == original.notes)
        #expect(decoded.isSynced == true)
        #expect(decoded.imageThumbnail == thumbnailData)
    }
}
