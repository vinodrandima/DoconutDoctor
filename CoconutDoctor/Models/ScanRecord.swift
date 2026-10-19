//
//  ScanRecord.swift
//  CoconutDoctor
//
//  Data model representing an offline leaf scan event.
//

import Foundation

public struct ScanRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public let disease: DiseaseType
    public let confidence: Double
    public let date: Date
    public let latitude: Double?
    public let longitude: Double?
    public let notes: String?
    public let imagePath: String?
    
    public init(
        id: UUID = UUID(),
        disease: DiseaseType,
        confidence: Double,
        date: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        notes: String? = nil,
        imagePath: String? = nil
    ) {
        self.id = id
        self.disease = disease
        self.confidence = confidence
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.imagePath = imagePath
    }
}
