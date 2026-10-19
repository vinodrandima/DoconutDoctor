//
//  MainTabView.swift
//  CoconutDoctor
//
//  Root navigation tab view for iPhone (to be upgraded to NavigationSplitView on iPad).
//

import SwiftUI

public enum AppTab: Hashable, CaseIterable {
    case detect
    case history
    case map
    case stats
}

public struct MainTabView: View {
    @State private var selectedTab: AppTab = .detect
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
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
        }
        .tint(.appAccent)
    }
}

#Preview {
    MainTabView()
        .withDependencies(.shared)
}
