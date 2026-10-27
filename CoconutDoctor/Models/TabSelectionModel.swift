//
//  TabSelectionModel.swift
//  CoconutDoctor
//
//  Shared tab selection state model enabling MVVM-compliant cross-tab navigation.
//

import SwiftUI
import Combine

@MainActor
public final class TabSelectionModel: ObservableObject {
    @Published public var selectedTab: AppTab
    
    public init(initialTab: AppTab = .home) {
        self.selectedTab = initialTab
    }
    
    public func navigate(to tab: AppTab) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.selectedTab = tab
        }
    }
}
