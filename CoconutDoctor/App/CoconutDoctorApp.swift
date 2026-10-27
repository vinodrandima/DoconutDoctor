//
//  CoconutDoctorApp.swift
//  CoconutDoctor
//
//  App entry point for CoconutDoctor.
//

import SwiftUI
import FirebaseCore

@main
struct CoconutDoctorApp: App {
    private let container: DependencyContainer
    
    init() {
        // Safe Firebase initialization with offline fallback
        if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           FileManager.default.fileExists(atPath: plistPath) {
            FirebaseApp.configure()
            print("✅ Firebase initialized successfully with GoogleService-Info.plist")
        } else {
            print("ℹ️ GoogleService-Info.plist not found in bundle. Running in offline/guest mode.")
        }
        
        let appContainer = DependencyContainer.shared
        self.container = appContainer
        
        // Configure local notification delegate & weekly inspection schedule
        UNUserNotificationCenter.current().delegate = appContainer.notificationService
        if appContainer.appSettings.isWeeklyInspectionEnabled {
            Task {
                await appContainer.notificationService.scheduleWeeklyInspection()
            }
        }
        
        if ProcessInfo.processInfo.arguments.contains("-seed") {
            let repo = appContainer.scanRepository
            Task {
                try? await repo.deleteAll()
                let size = CGSize(width: 180, height: 180)
                let renderer = UIGraphicsImageRenderer(size: size)
                
                let budRotData = renderer.image { ctx in
                    UIColor(red: 0.55, green: 0.25, blue: 0.15, alpha: 1.0).setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                }.jpegData(compressionQuality: 0.8)
                
                let healthyData = renderer.image { ctx in
                    UIColor(red: 0.18, green: 0.55, blue: 0.22, alpha: 1.0).setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                }.jpegData(compressionQuality: 0.8)
                
                // 3 Bud Rot (triggers spreading alert)
                try? await repo.save(ScanRecord(disease: .budRot, confidence: 0.96, date: Date().addingTimeInterval(-3600), latitude: 7.4863, longitude: 80.3623, imageThumbnail: budRotData))
                try? await repo.save(ScanRecord(disease: .budRot, confidence: 0.92, date: Date().addingTimeInterval(-86400 * 2), latitude: 7.4870, longitude: 80.3630, imageThumbnail: budRotData))
                try? await repo.save(ScanRecord(disease: .budRot, confidence: 0.89, date: Date().addingTimeInterval(-86400 * 4), latitude: 7.4880, longitude: 80.3640, imageThumbnail: budRotData))
                
                // 1 Leaf Rot
                try? await repo.save(ScanRecord(disease: .leafRot, confidence: 0.94, date: Date().addingTimeInterval(-86400 * 8), latitude: 7.4912, longitude: 80.3541, imageThumbnail: budRotData))
                
                // 2 Healthy
                try? await repo.save(ScanRecord(disease: .healthy, confidence: 0.99, date: Date().addingTimeInterval(-86400 * 12), latitude: 7.4920, longitude: 80.3550, imageThumbnail: healthyData))
                try? await repo.save(ScanRecord(disease: .healthy, confidence: 0.97, date: Date().addingTimeInterval(-86400 * 18), latitude: 7.4930, longitude: 80.3560, imageThumbnail: healthyData))
                
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("ScanRecordsUpdated"), object: nil)
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            let initialTab: AppTab = {
                if ProcessInfo.processInfo.arguments.contains("-detect") {
                    return .detect
                } else if ProcessInfo.processInfo.arguments.contains("-history") {
                    return .history
                } else if ProcessInfo.processInfo.arguments.contains("-map") {
                    return .map
                } else if ProcessInfo.processInfo.arguments.contains("-stats") {
                    return .stats
                } else if ProcessInfo.processInfo.arguments.contains("-settings") {
                    return .settings
                } else {
                    return .home
                }
            }()
            RootGateView(
                appSettings: container.appSettings,
                biometricService: container.biometricService,
                authService: container.authService,
                initialTab: initialTab
            )
            .withDependencies(container)
            .sheet(isPresented: .constant(ProcessInfo.processInfo.arguments.contains("-account"))) {
                AccountSheetView(syncManager: container.syncManager, authService: container.authService)
                    .withDependencies(container)
            }
            .sheet(isPresented: .constant(ProcessInfo.processInfo.arguments.contains("-alerts"))) {
                FarmAlertsSheetView(
                    diseaseAlert: DiseaseAlert(
                        disease: .budRot,
                        count: 3,
                        title: "Bud Rot Spreading Alert",
                        message: "Bud Rot detected in 3 scans this month. Inspect trees in this block.",
                        recommendation: "Prune affected fronds and apply recommended fungicide treatment promptly."
                    )
                )
                .withDependencies(container)
            }
        }
    }
}
