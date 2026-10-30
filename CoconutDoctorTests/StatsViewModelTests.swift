//
//  StatsViewModelTests.swift
//  CoconutDoctorTests
//
//  Unit tests for farm statistics aggregation, healthy-to-disease ratios,
//  and edge-case safety (0 scans) using Swift Testing.
//

import Testing
import Foundation
@testable import ios_coco

@Suite("Farm Analytics & Statistics Aggregation Tests")
struct StatsViewModelTests {
    
    @Test("Edge Case: Aggregating 0 scans resets all metrics safely without division-by-zero")
    @MainActor
    func testEmptyRecordsAggregation() {
        let vm = StatsViewModel()
        vm.aggregate(records: [])
        
        #expect(vm.totalScans == 0)
        #expect(vm.healthyCount == 0)
        #expect(vm.diseasedCount == 0)
        #expect(vm.mostCommonDisease == nil)
        #expect(vm.perDiseaseCounts.isEmpty)
        #expect(vm.scansPerWeek.isEmpty)
        #expect(vm.overallAverageConfidence == 0.0)
    }
    
    @Test("Aggregating healthy-only scans calculates 100% healthy ratio")
    @MainActor
    func testAllHealthyScans() {
        let vm = StatsViewModel()
        let records = [
            ScanRecord(disease: .healthy, confidence: 0.95),
            ScanRecord(disease: .healthy, confidence: 0.98),
            ScanRecord(disease: .healthy, confidence: 0.92)
        ]
        
        vm.aggregate(records: records)
        
        #expect(vm.totalScans == 3)
        #expect(vm.healthyCount == 3)
        #expect(vm.diseasedCount == 0)
        #expect(vm.mostCommonDisease == .healthy)
        
        let healthyEntry = vm.perDiseaseCounts.first(where: { $0.disease == .healthy })
        #expect(healthyEntry?.count == 3)
        #expect(healthyEntry?.percentage == 100.0)
    }
    
    @Test("Mixed diagnosis correctly ranks most common disease")
    @MainActor
    func testMixedDiseasesMostCommon() {
        let vm = StatsViewModel()
        let records = [
            ScanRecord(disease: .budRot, confidence: 0.90),
            ScanRecord(disease: .budRot, confidence: 0.92),
            ScanRecord(disease: .budRot, confidence: 0.94),
            ScanRecord(disease: .leafRot, confidence: 0.85),
            ScanRecord(disease: .healthy, confidence: 0.99)
        ]
        
        vm.aggregate(records: records)
        
        #expect(vm.totalScans == 5)
        #expect(vm.healthyCount == 1)
        #expect(vm.diseasedCount == 4)
        #expect(vm.mostCommonDisease == .budRot)
        
        let budRotEntry = vm.perDiseaseCounts.first(where: { $0.disease == .budRot })
        #expect(budRotEntry?.count == 3)
        #expect(budRotEntry?.percentage == 60.0)
    }
    
    @Test("Overall average confidence matches sum divided by count")
    @MainActor
    func testAverageConfidence() {
        let vm = StatsViewModel()
        let records = [
            ScanRecord(disease: .budRot, confidence: 0.80),
            ScanRecord(disease: .leafRot, confidence: 0.90)
        ]
        
        vm.aggregate(records: records)
        
        #expect(vm.totalScans == 2)
        #expect(abs(vm.overallAverageConfidence - 0.85) < 0.001)
    }
}
