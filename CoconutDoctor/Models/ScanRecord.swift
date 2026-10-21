//
//  ScanRecord.swift
//  CoconutDoctor
//
//  Immutable data model representing an offline leaf scan event.
//

import Foundation
import CoreLocation

public struct ScanRecord: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let diseaseLabel: String
    public let confidence: Double
    public let latitude: Double?
    public let longitude: Double?
    public let imageThumbnail: Data?
    public let treatmentSnapshot: String?
    public let notes: String?
    public let imagePath: String?
    
    // MARK: - Computed Properties
    
    public var disease: DiseaseType {
        DiseaseType(rawValue: diseaseLabel) ?? .healthy
    }
    
    /// Compatibility alias for views using `date`
    public var date: Date {
        timestamp
    }
    
    /// MapKit 2D coordinate for map annotations
    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // MARK: - Initializers
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        diseaseLabel: String,
        confidence: Double,
        latitude: Double? = nil,
        longitude: Double? = nil,
        imageThumbnail: Data? = nil,
        treatmentSnapshot: String? = nil,
        notes: String? = nil,
        imagePath: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.diseaseLabel = diseaseLabel
        self.confidence = confidence
        self.latitude = latitude
        self.longitude = longitude
        self.imageThumbnail = imageThumbnail
        self.treatmentSnapshot = treatmentSnapshot
        self.notes = notes
        self.imagePath = imagePath
    }
    
    /// Convenience initializer accepting DiseaseType directly
    public init(
        id: UUID = UUID(),
        disease: DiseaseType,
        confidence: Double,
        date: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        imageThumbnail: Data? = nil,
        treatmentSnapshot: String? = nil,
        notes: String? = nil,
        imagePath: String? = nil
    ) {
        self.init(
            id: id,
            timestamp: date,
            diseaseLabel: disease.rawValue,
            confidence: confidence,
            latitude: latitude,
            longitude: longitude,
            imageThumbnail: imageThumbnail,
            treatmentSnapshot: treatmentSnapshot,
            notes: notes,
            imagePath: imagePath
        )
    }
    
    // MARK: - ResultView Conversion
    
    public func toClassificationResult() -> ClassificationResult {
        let conf = Float(confidence)
        
        // If treatmentSnapshot contains serialized top predictions JSON, decode it faithfully
        if let snapshot = treatmentSnapshot,
           let data = snapshot.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ClassificationResult.PredictionEntry].self, from: data) {
            return ClassificationResult(
                disease: disease,
                confidence: conf,
                topPredictions: decoded.map { ($0.disease, $0.confidence) }
            )
        }
        
        // Otherwise, construct a reasonable top-prediction distribution
        let remaining = max(0.0, (1.0 - conf) / 2.0)
        let otherDisease: DiseaseType = (disease == .healthy) ? .budRot : .healthy
        return ClassificationResult(
            disease: disease,
            confidence: conf,
            topPredictions: [
                (disease: disease, confidence: conf),
                (disease: otherDisease, confidence: remaining)
            ]
        )
    }
}
