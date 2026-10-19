//
//  ClassificationResult.swift
//  CoconutDoctor
//
//  On-device ML classification result.
//

import Foundation

public struct ClassificationResult: Sendable, Codable, Equatable, Hashable {
    public let disease: DiseaseType
    public let confidence: Float
    public let topPredictions: [(disease: DiseaseType, confidence: Float)]
    
    public init(
        disease: DiseaseType,
        confidence: Float,
        topPredictions: [(disease: DiseaseType, confidence: Float)]
    ) {
        self.disease = disease
        self.confidence = confidence
        self.topPredictions = topPredictions
    }
    
    // MARK: - Codable Conformance
    
    private enum CodingKeys: String, CodingKey {
        case disease
        case confidence
        case topPredictions
    }
    
    public struct PredictionEntry: Codable, Sendable, Equatable, Hashable {
        public let disease: DiseaseType
        public let confidence: Float
        
        public init(disease: DiseaseType, confidence: Float) {
            self.disease = disease
            self.confidence = confidence
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.disease = try container.decode(DiseaseType.self, forKey: .disease)
        self.confidence = try container.decode(Float.self, forKey: .confidence)
        let entries = try container.decode([PredictionEntry].self, forKey: .topPredictions)
        self.topPredictions = entries.map { ($0.disease, $0.confidence) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(disease, forKey: .disease)
        try container.encode(confidence, forKey: .confidence)
        let entries = topPredictions.map { PredictionEntry(disease: $0.disease, confidence: $0.confidence) }
        try container.encode(entries, forKey: .topPredictions)
    }
    
    public static func == (lhs: ClassificationResult, rhs: ClassificationResult) -> Bool {
        guard lhs.disease == rhs.disease, abs(lhs.confidence - rhs.confidence) < 0.0001 else {
            return false
        }
        guard lhs.topPredictions.count == rhs.topPredictions.count else {
            return false
        }
        for (p1, p2) in zip(lhs.topPredictions, rhs.topPredictions) {
            if p1.disease != p2.disease || abs(p1.confidence - p2.confidence) >= 0.0001 {
                return false
            }
        }
        return true
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(disease)
        hasher.combine(confidence)
        for pred in topPredictions {
            hasher.combine(pred.disease)
            hasher.combine(pred.confidence)
        }
    }
}
