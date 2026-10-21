//
//  LocationManager.swift
//  CoconutDoctor
//
//  Observable Core Location manager handling user GPS tracking, permissions, and geo-tagging.
//

import Foundation
import CoreLocation
import Combine

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
    @Published public var userLocation: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus
    @Published public var isLocationAuthorized: Bool = false
    @Published public var locationError: String?
    
    private let manager = CLLocationManager()
    
    /// Default fallback center in Sri Lanka's Coconut Triangle (Kurunegala/North-Western Province)
    public static let sriLankaCoconutTriangle = CLLocationCoordinate2D(
        latitude: 7.4863,
        longitude: 80.3623
    )
    
    public override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        updateAuthorizationState(status: manager.authorizationStatus)
    }
    
    public var lastKnownCoordinate: CLLocationCoordinate2D? {
        userLocation?.coordinate
    }
    
    public func requestWhenInUseAuthorization() {
        DispatchQueue.main.async { [weak self] in
            self?.manager.requestWhenInUseAuthorization()
        }
    }
    
    public func startUpdatingLocation() {
        DispatchQueue.main.async { [weak self] in
            self?.manager.startUpdatingLocation()
        }
    }
    
    public func stopUpdatingLocation() {
        DispatchQueue.main.async { [weak self] in
            self?.manager.stopUpdatingLocation()
        }
    }
    
    public func requestLocation() {
        DispatchQueue.main.async { [weak self] in
            self?.manager.requestLocation()
        }
    }
    
    private func updateAuthorizationState(status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            self.isLocationAuthorized = true
            manager.startUpdatingLocation()
        case .denied, .restricted:
            self.isLocationAuthorized = false
            self.stopUpdatingLocation()
        case .notDetermined:
            self.isLocationAuthorized = false
        @unknown default:
            self.isLocationAuthorized = false
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.updateAuthorizationState(status: manager.authorizationStatus)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = latest
            self?.locationError = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.locationError = error.localizedDescription
            print("LocationManager: didFailWithError: \(error.localizedDescription)")
        }
    }
}
