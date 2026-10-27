//
//  MainTabView.swift
//  CoconutDoctor
//
//  Root navigation tab view for iPhone with Home Dashboard as the primary tab.
//

import SwiftUI

public enum AppTab: Hashable, CaseIterable {
    case home
    case detect
    case history
    case map
    case stats
    case settings
}

public struct MainTabView: View {
    @StateObject private var tabSelection: TabSelectionModel
    
    public init(initialTab: AppTab = .home) {
        _tabSelection = StateObject(wrappedValue: TabSelectionModel(initialTab: initialTab))
    }
    
    public var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            DashboardView(tabSelection: tabSelection)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)
            
            DetectionView()
                .tabItem {
                    Label("Detect", systemImage: "camera.viewfinder")
                }
                .tag(AppTab.detect)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)
            
            FarmMapView()
                .tabItem {
                    Label("Farm Map", systemImage: "map")
                }
                .tag(AppTab.map)
            
            StatsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis")
                }
                .tag(AppTab.stats)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(.appAccent)
        .environmentObject(tabSelection)
    }
}

#Preview {
    MainTabView()
        .withDependencies(.shared)
}
