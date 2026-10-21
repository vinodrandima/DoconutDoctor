//
//  TreatmentService.swift
//  CoconutDoctor
//
//  Service providing localized agricultural treatment advice and disease care.
//

import Foundation

public protocol TreatmentServiceProtocol: Sendable {
    func getTreatment(for disease: DiseaseType, language: AppLanguage) -> TreatmentInfo
    func getTreatment(for disease: DiseaseType) -> TreatmentInfo
}

public final class TreatmentService: TreatmentServiceProtocol, @unchecked Sendable {
    public static let shared = TreatmentService()
    
    /// Stored treatments indexed by "\(disease.rawValue)_\(language.rawValue)"
    private let treatmentsCache: [String: TreatmentInfo]
    
    public init(bundle: Bundle = .main) {
        var loadedTreatments: [String: TreatmentInfo] = [:]
        
        if let url = bundle.url(forResource: "Treatments", withExtension: "json") ??
                     Bundle(for: TreatmentService.self).url(forResource: "Treatments", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([TreatmentInfo].self, from: data) {
            for item in list {
                let key = "\(item.disease.rawValue)_\(item.language)"
                loadedTreatments[key] = item
            }
        } else {
            #if DEBUG
            print("[TreatmentService] Note: Treatments.json not found in bundle, using embedded fallback dataset.")
            #endif
            loadedTreatments = Self.fallbackTreatments()
        }
        
        self.treatmentsCache = loadedTreatments
    }
    
    public func getTreatment(for disease: DiseaseType, language: AppLanguage) -> TreatmentInfo {
        let key = "\(disease.rawValue)_\(language.rawValue)"
        if let found = treatmentsCache[key] {
            return found
        }
        
        // Fallback to English
        let fallbackKey = "\(disease.rawValue)_en"
        if let english = treatmentsCache[fallbackKey] {
            return english
        }
        
        // Ultimate default
        return TreatmentInfo(
            disease: disease,
            language: language.rawValue,
            title: disease.displayName,
            description: "No specific treatment guidelines available.",
            chemicalTreatment: ["Consult an agricultural extension officer."],
            organicTreatment: ["Maintain general palm health and sanitation."],
            preventionTips: ["Regularly inspect your plantation."]
        )
    }
    
    public func getTreatment(for disease: DiseaseType) -> TreatmentInfo {
        let currentLang = AppLanguage.currentDeviceLanguage
        return getTreatment(for: disease, language: currentLang)
    }
    
    // MARK: - Safe In-Memory Fallback
    
    private static func fallbackTreatments() -> [String: TreatmentInfo] {
        var map: [String: TreatmentInfo] = [:]
        
        // Quick English fallbacks for all 5 diseases
        let entries: [(DiseaseType, String, [String], [String], [String])] = [
            (.budRot, "Bud Rot",
             ["Apply 1% Bordeaux paste or Copper Oxychloride to the crown.", "Drench bud with Mancozeb (0.2%)."],
             ["Cut away rotting spear tissues down to healthy wood and burn.", "Paste neem seed powder and wood ash over the crown."],
             ["Improve field drainage.", "Sterilize harvesting knives."]),
            (.greyLeafSpot, "Grey Leaf Spot",
             ["Spray foliage with Mancozeb (2g/L) or Carbendazim (1g/L)."],
             ["Apply potassium-rich wood ash and compost.", "Spray 5% neem oil emulsion."],
             ["Prune and burn heavily infected dead lower fronds.", "Apply MOP potash."]),
            (.leafRot, "Leaf Rot",
             ["Pour Hexaconazole (5% EC, 2ml/300ml) into crown leaf axils."],
             ["Apply Trichoderma enriched compost to root basin.", "Mulch with coconut husks."],
             ["Avoid mechanical root damage.", "Irrigate during droughts."]),
            (.stemBleeding, "Stem Bleeding",
             ["Chisel out diseased trunk tissues and paint with Carbendazim.", "Seal with hot coal tar."],
             ["Apply thick Bordeaux paste to scraped wood.", "Apply 5 kg neem cake around palm root zone."],
             ["Prevent trunk wounds during weeding.", "Improve soil drainage."]),
            (.healthy, "Healthy Coconut Palm",
             ["No chemicals needed! Apply recommended CRI Adult Palm Mixture (APM)."],
             ["Apply 25-30 kg organic manure or compost annually.", "Bury husks for moisture."],
             ["Keep 1.5m radius free of weeds.", "Inspect monthly for beetle damage."])
        ]
        
        for item in entries {
            let info = TreatmentInfo(
                disease: item.0,
                language: "en",
                title: item.1,
                description: "Standard CRISL agronomic guidelines.",
                chemicalTreatment: item.2,
                organicTreatment: item.3,
                preventionTips: item.4
            )
            map["\(item.0.rawValue)_en"] = info
        }
        
        return map
    }
}
