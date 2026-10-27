//
//  DashboardViewModel.swift
//  CoconutDoctor
//
//  ViewModel powering the Home Dashboard tab. Reuses StatsViewModel logic to avoid
//  duplicate queries and computes recent scans, alerts, and farm metrics.
//

import Foundation
import SwiftUI
import Combine

public struct DiseaseAlert: Identifiable, Equatable {
    public let id = UUID()
    public let disease: DiseaseType
    public let count: Int
    public let title: String
    public let message: String
    public let recommendation: String
}

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var recentScans: [ScanRecord] = []
    @Published public var scansThisWeekCount: Int = 0
    @Published public var scansLastWeekCount: Int = 0
    @Published public var diseaseAlert: DiseaseAlert?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public let statsViewModel: StatsViewModel
    private let scanRepository: ScanRepositoryProtocol
    private let authService: AuthService
    private let appSettings: AppSettings
    
    public init(
        statsViewModel: StatsViewModel? = nil,
        scanRepository: ScanRepositoryProtocol? = nil,
        authService: AuthService? = nil,
        appSettings: AppSettings? = nil
    ) {
        let repo = scanRepository ?? DependencyContainer.shared.scanRepository
        self.scanRepository = repo
        self.statsViewModel = statsViewModel ?? StatsViewModel(scanRepository: repo)
        self.authService = authService ?? DependencyContainer.shared.authService
        self.appSettings = appSettings ?? DependencyContainer.shared.appSettings
    }
    
    // MARK: - Data Fetching
    
    public func loadDashboard() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                // Fetch once from Core Data and reuse across StatsViewModel and Dashboard
                let records = try await scanRepository.fetchAll()
                
                // 1. Reuse existing StatsViewModel aggregation logic (Zero duplicate queries)
                self.statsViewModel.aggregate(records: records)
                
                // 2. Compute Dashboard-specific metrics
                self.computeDashboardData(records: records)
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Farmer-friendly greeting adapted for time-of-day and selected language (EN, SI, TA)
    public var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let lang = appSettings.selectedLanguage
        
        switch hour {
        case 5..<12:
            switch lang {
            case .sinhala: return "සුබ උදෑසනක්"
            case .tamil: return "காலை வணக்கம்"
            case .english: return "Good Morning"
            }
        case 12..<17:
            switch lang {
            case .sinhala: return "සුබ දහවලක්"
            case .tamil: return "மதிய வணக்கம்"
            case .english: return "Good Afternoon"
            }
        default:
            switch lang {
            case .sinhala: return "සුබ සන්ධ්‍යාවක්"
            case .tamil: return "மாலை வணக்கம்"
            case .english: return "Good Evening"
            }
        }
    }
    
    /// Farmer identifier: email prefix if authenticated, or culturally friendly Guest moniker
    public var farmerName: String {
        if case .signedIn = authService.authState {
            if let email = authService.currentUserEmail, !email.isEmpty {
                let prefix = email.components(separatedBy: "@").first ?? "Farmer"
                return prefix.prefix(1).uppercased() + prefix.dropFirst()
            }
            return "Farmer"
        } else {
            switch appSettings.selectedLanguage {
            case .sinhala: return "ගොවි මහතා"
            case .tamil: return "விவசாயி"
            case .english: return "Farmer"
            }
        }
    }
    
    /// Farm health ratio between 0.0 and 1.0
    public var healthRatio: Double {
        guard statsViewModel.totalScans > 0 else { return 0.0 }
        return Double(statsViewModel.healthyCount) / Double(statsViewModel.totalScans)
    }
    
    /// Formatted health ratio percentage string
    public var healthRatioFormatted: String {
        guard statsViewModel.totalScans > 0 else { return "0%" }
        return String(format: "%.0f%%", healthRatio * 100.0)
    }
    
    /// Weekly trend comparison difference
    public var weeklyTrendDelta: Int {
        scansThisWeekCount - scansLastWeekCount
    }
    
    // MARK: - Internal Metrics Processing
    
    private func computeDashboardData(records: [ScanRecord]) {
        // 1. Latest 3 scans sorted descending
        let sorted = records.sorted(by: { $0.timestamp > $1.timestamp })
        self.recentScans = Array(sorted.prefix(3))
        
        // 2. Weekly scan counts (This week vs Last week)
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday start
        let now = Date()
        
        if let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) {
            let startThisWeek = currentWeek.start
            let endThisWeek = currentWeek.end
            
            let startLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startThisWeek) ?? startThisWeek.addingTimeInterval(-7*86400)
            let endLastWeek = startThisWeek
            
            self.scansThisWeekCount = records.filter { $0.timestamp >= startThisWeek && $0.timestamp < endThisWeek }.count
            self.scansLastWeekCount = records.filter { $0.timestamp >= startLastWeek && $0.timestamp < endLastWeek }.count
        } else {
            self.scansThisWeekCount = 0
            self.scansLastWeekCount = 0
        }
        
        // 3. Disease Alert: if any disease count >= 3 scans this month
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now.addingTimeInterval(-30*86400)
        let monthScans = records.filter { $0.timestamp >= oneMonthAgo && $0.disease != .healthy }
        
        var diseaseMonthCounts: [DiseaseType: Int] = [:]
        for scan in monthScans {
            diseaseMonthCounts[scan.disease, default: 0] += 1
        }
        
        // Pick disease with highest frequency that reached threshold >= 3
        if let topOutbreak = diseaseMonthCounts.filter({ $0.value >= 3 }).max(by: { $0.value < $1.value }) {
            let disease = topOutbreak.key
            let count = topOutbreak.value
            
            let title: String
            let message: String
            let rec: String
            
            switch appSettings.selectedLanguage {
            case .sinhala:
                title = "\(disease.displayName) පැතිරීමේ අවදානමක්"
                message = "පසුගිය දින 30 තුළ \(disease.displayName) ආසාදන \(count) ක් හමුවී ඇත. ඔබගේ ගස් පරීක්ෂා කරන්න."
                rec = "වහාම ආසාදිත මට්ටල් කපා දමා පිළිස්සීම හෝ නිර්දේශිත දිලීර නාශක යොදන්න."
            case .tamil:
                title = "\(disease.displayName) பரவல் எச்சரிக்கை"
                message = "கடந்த 30 நாட்களில் \(count) முறை \(disease.displayName) கண்டறியப்பட்டுள்ளது. மரங்களைச் சரிபார்க்கவும்."
                rec = "பாதிக்கப்பட்ட பகுதிகளை அகற்றி பரிந்துரைக்கப்பட்ட பூஞ்சைக் கொல்லியைப் பயன்படுத்தவும்."
            case .english:
                title = "\(disease.displayName) Spreading Alert"
                message = "\(disease.displayName) detected in \(count) scans this month. Inspect trees in this block."
                rec = "Prune affected fronds and apply recommended fungicide treatment promptly."
            }
            
            self.diseaseAlert = DiseaseAlert(
                disease: disease,
                count: count,
                title: title,
                message: message,
                recommendation: rec
            )
        } else {
            self.diseaseAlert = nil
        }
    }
}
