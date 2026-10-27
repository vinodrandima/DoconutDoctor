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
        
        self.container = DependencyContainer.shared
    }
    
    var body: some Scene {
        WindowGroup {
            let initialTab: AppTab = {
                if ProcessInfo.processInfo.arguments.contains("-history") {
                    return .history
                } else if ProcessInfo.processInfo.arguments.contains("-map") {
                    return .map
                } else if ProcessInfo.processInfo.arguments.contains("-stats") {
                    return .stats
                } else if ProcessInfo.processInfo.arguments.contains("-settings") {
                    return .settings
                } else {
                    return .detect
                }
            }()
            RootGateView(
                appSettings: container.appSettings,
                biometricService: container.biometricService,
                initialTab: initialTab
            )
            .withDependencies(container)
            .sheet(isPresented: .constant(ProcessInfo.processInfo.arguments.contains("-login"))) {
                LoginView(authService: container.authService)
            }
            .sheet(isPresented: .constant(ProcessInfo.processInfo.arguments.contains("-account"))) {
                AccountSheetView(syncManager: container.syncManager, authService: container.authService)
                    .withDependencies(container)
            }
        }
    }
}
