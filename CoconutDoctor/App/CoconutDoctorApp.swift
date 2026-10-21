//
//  CoconutDoctorApp.swift
//  CoconutDoctor
//
//  App entry point for CoconutDoctor.
//

import SwiftUI

@main
struct CoconutDoctorApp: App {
    private let container = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            let initialTab: AppTab = {
                if ProcessInfo.processInfo.arguments.contains("-history") {
                    return .history
                } else if ProcessInfo.processInfo.arguments.contains("-map") {
                    return .map
                } else if ProcessInfo.processInfo.arguments.contains("-stats") {
                    return .stats
                } else {
                    return .detect
                }
            }()
            MainTabView(initialTab: initialTab)
                .withDependencies(container)
        }
    }
}
