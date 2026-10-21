//
//  MapViewModel.swift
//  CoconutDoctor
//
//  ViewModel managing disease map pins, geo-tagged scan fetching, and MapKit camera control.
//

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
public final class MapViewModel: ObservableObject {
    @Published public var geoScans: [ScanRecord] = []
    @Published public var selectedScan: ScanRecord?
    @Published public var selectedDiseaseFilter: DiseaseType?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var cameraPosition: MapCameraPosition = .automatic
    
    private let scanRepository: ScanRepositoryProtocol
    public let locationManager: LocationManager
    
    public init(
        scanRepository: ScanRepositoryProtocol? = nil,
        locationManager: LocationManager? = nil
    ) {
        self.scanRepository = scanRepository ?? DependencyContainer.shared.scanRepository
        self.locationManager = locationManager ?? DependencyContainer.shared.locationManager
        
        // Start camera over Sri Lanka's Coconut Triangle by default
        self.cameraPosition = .region(MKCoordinateRegion(
            center: LocationManager.sriLankaCoconutTriangle,
            span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
        ))
    }
    
    public var filteredScans: [ScanRecord] {
        if let filter = selectedDiseaseFilter {
            return geoScans.filter { $0.disease == filter }
        }
        return geoScans
    }
    
    public func fetchGeoScans() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let records = try await scanRepository.fetchAll()
                let geoTagged = records.filter { $0.coordinate != nil }
                self.geoScans = geoTagged
                self.isLoading = false
                
                // If we have pins and camera is currently default, center on pins and select newest
                if !geoTagged.isEmpty && selectedScan == nil {
                    fitPins(geoTagged)
                    self.selectedScan = geoTagged.first
                }
            } catch {
                self.errorMessage = "Failed to load farm map scans: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    public func selectScan(_ scan: ScanRecord?) {
        self.selectedScan = scan
        if let coord = scan?.coordinate {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                self.cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }
    
    public func centerOnUserLocation() {
        if let userCoord = locationManager.lastKnownCoordinate {
            withAnimation(.easeInOut) {
                self.cameraPosition = .region(MKCoordinateRegion(
                    center: userCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        } else {
            locationManager.requestLocation()
        }
    }
    
    public func fitPins(_ pins: [ScanRecord]) {
        let validCoords = pins.compactMap { $0.coordinate }
        guard !validCoords.isEmpty else { return }
        
        if validCoords.count == 1, let first = validCoords.first {
            self.cameraPosition = .region(MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
            return
        }
        
        var minLat = validCoords[0].latitude
        var maxLat = validCoords[0].latitude
        var minLon = validCoords[0].longitude
        var maxLon = validCoords[0].longitude
        
        for coord in validCoords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.08, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.08, (maxLon - minLon) * 1.5)
        )
        
        withAnimation(.easeInOut) {
            self.cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}
