//
//  TreatmentInfo.swift
//  CoconutDoctor
//
//  Farmer-friendly treatment advice and care guidelines.
//

import Foundation

public struct TreatmentInfo: Identifiable, Codable, Sendable, Equatable, Hashable {
    public var id: String { "\(disease.rawValue)_\(language)" }
    public let disease: DiseaseType
    public let language: String
    public let title: String
    public let scientificName: String?
    public let description: String
    public let chemicalTreatment: [String]
    public let organicTreatment: [String]
    public let preventionTips: [String]
    public let consultationNote: String
    
    public init(
        disease: DiseaseType,
        language: String,
        title: String,
        scientificName: String? = nil,
        description: String,
        chemicalTreatment: [String],
        organicTreatment: [String],
        preventionTips: [String],
        consultationNote: String = "Always consult your local Agriculture Instructor (AI) or Coconut Cultivation Board (CCB) officer before purchasing or applying chemical fungicides."
    ) {
        self.disease = disease
        self.language = language
        self.title = title
        self.scientificName = scientificName
        self.description = description
        self.chemicalTreatment = chemicalTreatment
        self.organicTreatment = organicTreatment
        self.preventionTips = preventionTips
        self.consultationNote = consultationNote
    }
}
