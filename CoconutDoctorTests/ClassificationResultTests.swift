//
//  ClassificationResultTests.swift
//  CoconutDoctorTests
//
//  Unit tests for ML classification results, confidence thresholds,
//  and Codable serialization using Swift Testing.
//

import Testing
import Foundation
@testable import ios_coco

@Suite("ML Classification Result Tests")
struct ClassificationResultTests {
    
    @Test("ClassificationResult initializes correctly with top predictions")
    func testInitialization() {
        let topPredictions: [(disease: DiseaseType, confidence: Float)] = [
            (.budRot, 0.94),
            (.leafRot, 0.04),
            (.healthy, 0.02)
        ]
        
        let result = ClassificationResult(
            disease: .budRot,
            confidence: 0.94,
            topPredictions: topPredictions
        )
        
        #expect(result.disease == .budRot)
        #expect(abs(result.confidence - 0.94) < 0.001)
        #expect(result.topPredictions.count == 3)
        #expect(result.topPredictions.first?.disease == .budRot)
    }
    
    @Test("ClassificationResult Codable roundtrip preserves all probabilities")
    func testCodableRoundtrip() throws {
        let original = ClassificationResult(
            disease: .greyLeafSpot,
            confidence: 0.88,
            topPredictions: [
                (.greyLeafSpot, 0.88),
                (.leafRot, 0.08),
                (.healthy, 0.04)
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClassificationResult.self, from: data)
        
        #expect(decoded == original)
        #expect(decoded.disease == original.disease)
        #expect(abs(decoded.confidence - original.confidence) < 0.0001)
        #expect(decoded.topPredictions.count == original.topPredictions.count)
    }
    
    @Test("Edge Case: Boundary confidence values (0.0 and 1.0) serialize safely")
    func testBoundaryConfidenceValues() throws {
        let zeroConfidence = ClassificationResult(
            disease: .healthy,
            confidence: 0.0,
            topPredictions: [(disease: .healthy, confidence: 0.0)]
        )
        let fullConfidence = ClassificationResult(
            disease: .stemBleeding,
            confidence: 1.0,
            topPredictions: [(disease: .stemBleeding, confidence: 1.0)]
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let zeroDecoded = try decoder.decode(ClassificationResult.self, from: encoder.encode(zeroConfidence))
        let fullDecoded = try decoder.decode(ClassificationResult.self, from: encoder.encode(fullConfidence))
        
        #expect(abs(zeroDecoded.confidence - 0.0) < 0.0001)
        #expect(abs(fullDecoded.confidence - 1.0) < 0.0001)
    }
    
    @Test("Equality comparator correctly checks precision tolerance")
    func testEqualityTolerance() {
        let r1 = ClassificationResult(
            disease: .leafRot,
            confidence: 0.85001,
            topPredictions: [(.leafRot, 0.85001)]
        )
        let r2 = ClassificationResult(
            disease: .leafRot,
            confidence: 0.85002,
            topPredictions: [(.leafRot, 0.85002)]
        )
        let r3 = ClassificationResult(
            disease: .leafRot,
            confidence: 0.86,
            topPredictions: [(.leafRot, 0.86)]
        )
        
        #expect(r1 == r2, "Results differing by less than 0.0001 should be considered equal.")
        #expect(r1 != r3, "Results differing by more than 0.0001 should not be equal.")
    }
}
