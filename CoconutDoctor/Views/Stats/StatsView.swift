//
//  StatsView.swift
//  CoconutDoctor
//
//  Disease trends & health statistics dashboard tab.
//

import SwiftUI

public struct StatsView: View {
    @Environment(\.dependencies) private var dependencies
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Disease Statistics",
                systemImage: "chart.bar.xaxis",
                description: Text("Swift Charts visual summaries and health breakdown of scanned palms.")
            )
            .navigationTitle("Statistics")
        }
    }
}

#Preview {
    StatsView()
}
