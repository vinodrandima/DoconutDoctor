//
//  StatsViewModel.swift
//  CoconutDoctor
//
//  ViewModel aggregating offline scan history into visual metrics, disease distributions,
//  and multi-week diagnostic trends for Swift Charts.
//

import Foundation
import SwiftUI
import Combine

public struct DiseaseCountItem: Identifiable, Equatable {
    public var id: DiseaseType { disease }
    public let disease: DiseaseType
    public let count: Int
    public let percentage: Double
    
    public init(disease: DiseaseType, count: Int, total: Int) {
        self.disease = disease
        self.count = count
        self.percentage = total > 0 ? (Double(count) / Double(total)) * 100.0 : 0.0
    }
}

public struct WeeklyScanItem: Identifiable, Equatable {
    public var id: Date { weekStart }
    public let weekStart: Date
    public let count: Int
    
    public init(weekStart: Date, count: Int) {
        self.weekStart = weekStart
        self.count = count
    }
}

public struct DiseaseConfidenceItem: Identifiable, Equatable {
    public var id: DiseaseType { disease }
    public let disease: DiseaseType
    public let averageConfidence: Double
    public let count: Int
}

@MainActor
public final class StatsViewModel: ObservableObject {
    @Published public var totalScans: Int = 0
    @Published public var perDiseaseCounts: [DiseaseCountItem] = []
    @Published public var scansPerWeek: [WeeklyScanItem] = []
    @Published public var avgConfidencePerDisease: [DiseaseConfidenceItem] = []
    @Published public var overallAverageConfidence: Double = 0.0
    @Published public var mostCommonDisease: DiseaseType?
    @Published public var healthyCount: Int = 0
    @Published public var diseasedCount: Int = 0
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let scanRepository: ScanRepositoryProtocol
    
    public init(scanRepository: ScanRepositoryProtocol? = nil) {
        self.scanRepository = scanRepository ?? DependencyContainer.shared.scanRepository
    }
    
    public func fetchStatistics() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let records = try await scanRepository.fetchAll()
                self.aggregate(records: records)
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load statistics: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    public func aggregate(records: [ScanRecord]) {
        self.totalScans = records.count
        
        guard !records.isEmpty else {
            self.perDiseaseCounts = []
            self.scansPerWeek = []
            self.avgConfidencePerDisease = []
            self.overallAverageConfidence = 0.0
            self.mostCommonDisease = nil
            self.healthyCount = 0
            self.diseasedCount = 0
            return
        }
        
        // 1. Per Disease Counts
        var countMap: [DiseaseType: Int] = [:]
        var confSumMap: [DiseaseType: Double] = [:]
        
        for disease in DiseaseType.allCases {
            countMap[disease] = 0
            confSumMap[disease] = 0.0
        }
        
        var totalConfidenceSum = 0.0
        for scan in records {
            countMap[scan.disease, default: 0] += 1
            confSumMap[scan.disease, default: 0.0] += scan.confidence
            totalConfidenceSum += scan.confidence
        }
        
        let countsList = DiseaseType.allCases.map { disease in
            DiseaseCountItem(disease: disease, count: countMap[disease] ?? 0, total: records.count)
        }.sorted(by: { $0.count > $1.count })
        self.perDiseaseCounts = countsList
        
        // Most common disease
        self.mostCommonDisease = countsList.first(where: { $0.count > 0 })?.disease
        
        // Healthy vs Diseased breakdown
        self.healthyCount = countMap[.healthy] ?? 0
        self.diseasedCount = records.count - (countMap[.healthy] ?? 0)
        
        // 2. Average Confidence Overall & Per Disease
        self.overallAverageConfidence = totalConfidenceSum / Double(records.count)
        
        self.avgConfidencePerDisease = DiseaseType.allCases.compactMap { disease -> DiseaseConfidenceItem? in
            let count = countMap[disease] ?? 0
            guard count > 0 else { return nil }
            let avg = (confSumMap[disease] ?? 0.0) / Double(count)
            return DiseaseConfidenceItem(disease: disease, averageConfidence: avg, count: count)
        }.sorted(by: { $0.count > $1.count })
        
        // 3. Scans Per Week (Last 8 Weeks)
        self.scansPerWeek = calculateLast8Weeks(from: records)
    }
    
    private func calculateLast8Weeks(from records: [ScanRecord]) -> [WeeklyScanItem] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday start
        let now = Date()
        
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
        var weekStarts: [Date] = []
        for offset in (0..<8).reversed() {
            if let date = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekInterval.start) {
                weekStarts.append(date)
            }
        }
        
        return weekStarts.map { weekStart in
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart.addingTimeInterval(7 * 86400)
            let count = records.filter { record in
                record.timestamp >= weekStart && record.timestamp < weekEnd
            }.count
            return WeeklyScanItem(weekStart: weekStart, count: count)
        }
    }
}
