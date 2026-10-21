//
//  DetectionViewModel.swift
//  CoconutDoctor
//
//  ViewModel coordinating image selection, camera capture, and on-device disease diagnosis.
//

import UIKit
import SwiftUI
import Combine
import CoreLocation

@MainActor
public final class DetectionViewModel: ObservableObject {
    public enum State: Equatable {
        case idle
        case analyzing
        case success(ClassificationResult)
        case error(String)
        
        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.analyzing, .analyzing):
                return true
            case (.success(let l), .success(let r)):
                return l == r
            case (.error(let l), .error(let r)):
                return l == r
            default:
                return false
            }
        }
    }
    
    @Published public var selectedImage: UIImage?
    @Published public var state: State = .idle
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    
    private let mlService: MLServiceProtocol
    private let scanRepository: ScanRepositoryProtocol
    private let locationManager: LocationManager
    
    public init(
        mlService: MLServiceProtocol? = nil,
        scanRepository: ScanRepositoryProtocol? = nil,
        locationManager: LocationManager? = nil
    ) {
        self.mlService = mlService ?? DependencyContainer.shared.mlService
        self.scanRepository = scanRepository ?? DependencyContainer.shared.scanRepository
        self.locationManager = locationManager ?? DependencyContainer.shared.locationManager
    }
    
    public func selectImage(_ image: UIImage) {
        self.selectedImage = image
        self.state = .idle
        self.errorMessage = nil
        self.showErrorAlert = false
        // Request location authorization early when user prepares to diagnose
        if !locationManager.isLocationAuthorized {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func analyze() {
        guard let image = selectedImage else {
            presentError("Please select or capture a photo first.")
            return
        }
        analyze(image: image)
    }
    
    public func analyze(image: UIImage) {
        self.selectedImage = image
        self.state = .analyzing
        self.errorMessage = nil
        self.showErrorAlert = false
        
        Task {
            do {
                let result = try await mlService.classify(image: image)
                self.state = .success(result)
                
                // Auto-save scan record to offline repository
                await autoSaveScan(result: result, image: image)
            } catch {
                let message = error.localizedDescription
                self.state = .error(message)
                self.presentError(message)
            }
        }
    }
    
    private func autoSaveScan(result: ClassificationResult, image: UIImage) async {
        // Prepare optimized thumbnail
        let thumbnail = image.preparingThumbnail(of: CGSize(width: 320, height: 320)) ?? image
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
        
        // Encode top predictions breakdown for faithful history viewing
        let predictionsData = try? JSONEncoder().encode(result.topPredictions.map {
            ClassificationResult.PredictionEntry(disease: $0.disease, confidence: $0.confidence)
        })
        let treatmentSnapshot = predictionsData.flatMap { String(data: $0, encoding: .utf8) }
        
        // Capture GPS location: live location if authorized, otherwise default to farm triangle coordinates
        let liveCoordinate = locationManager.lastKnownCoordinate
        let latitude: Double? = liveCoordinate?.latitude ?? LocationManager.sriLankaCoconutTriangle.latitude
        let longitude: Double? = liveCoordinate?.longitude ?? LocationManager.sriLankaCoconutTriangle.longitude
        
        let record = ScanRecord(
            id: UUID(),
            timestamp: Date(),
            diseaseLabel: result.disease.rawValue,
            confidence: Double(result.confidence),
            latitude: latitude,
            longitude: longitude,
            imageThumbnail: thumbnailData,
            treatmentSnapshot: treatmentSnapshot
        )
        
        do {
            try await scanRepository.save(record)
        } catch {
            print("DetectionViewModel: Warning — failed to auto-save scan record: \(error)")
        }
    }
    
    public func reset() {
        self.selectedImage = nil
        self.state = .idle
        self.errorMessage = nil
        self.showErrorAlert = false
    }
    
    public func presentError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}
