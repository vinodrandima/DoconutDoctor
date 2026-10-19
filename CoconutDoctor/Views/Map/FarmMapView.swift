//
//  FarmMapView.swift
//  CoconutDoctor
//
//  MapKit farm map with disease pins tab.
//

import SwiftUI

public struct FarmMapView: View {
    @Environment(\.dependencies) private var dependencies
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Farm Map",
                systemImage: "map",
                description: Text("Interactive farm map displaying geo-tagged leaf disease pins across your plantation.")
            )
            .navigationTitle("Farm Map")
        }
    }
}

#Preview {
    FarmMapView()
}
