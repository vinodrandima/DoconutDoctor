//
//  HistoryView.swift
//  CoconutDoctor
//
//  Offline scan history tab.
//

import SwiftUI

public struct HistoryView: View {
    @Environment(\.dependencies) private var dependencies
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Scan History",
                systemImage: "clock.arrow.circlepath",
                description: Text("Past leaf scans and diagnostic results will be stored here locally.")
            )
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
