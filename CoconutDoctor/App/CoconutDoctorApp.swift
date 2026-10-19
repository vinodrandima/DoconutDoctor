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
            // Root tab view for iPhone.
            // Note: In an upcoming step, this will adapt dynamically to
            // NavigationSplitView when running on iPadOS or expanded horizontal size classes.
            MainTabView()
                .withDependencies(container)
        }
    }
}
