//
//  MLService.swift
//  CoconutDoctor
//
//  Production Core ML + Vision on-device inference service.
//

import UIKit
import CoreML
import Vision
import ImageIO

public enum MLError: LocalizedError, Sendable {
    case modelNotFound
    case inferenceFailed(String)
    case invalidResult
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "The CoconutDoctor Core ML model could not be found or initialized."
        case .inferenceFailed(let message):
            return "Inference failed: \(message)"
        case .invalidResult:
            return "The model returned an invalid or empty classification result."
        }
    }
}

public final class MLService: MLServiceProtocol, @unchecked Sendable {
    private let vnModel: VNCoreMLModel?
    private let modelInitError: MLError?
    
    /// Exact model class ordering as specified by training outputs:
    /// index 0: BudRot
    /// index 1: GreyLeafSpot
    /// index 2: LeafRot
    /// index 3: StemBleeding
    /// index 4: Healthy
    public static let orderedClasses: [DiseaseType] = [
        .budRot,
        .greyLeafSpot,
        .leafRot,
        .stemBleeding,
        .healthy
    ]
    
    public init() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            // CoconutDoctor auto-compiled from Resources/CoconutDoctor.mlpackage
            let compiledModel = try CoconutDoctor(configuration: config)
            self.vnModel = try VNCoreMLModel(for: compiledModel.model)
            self.modelInitError = nil
        } catch {
            self.vnModel = nil
            self.modelInitError = .modelNotFound
            #if DEBUG
            print("[MLService] Error loading CoconutDoctor model: \(error.localizedDescription)")
            #endif
        }
    }
    
    public func classify(image: UIImage) async throws -> ClassificationResult {
        guard let vnModel = self.vnModel else {
            throw self.modelInitError ?? .modelNotFound
        }
        
        guard let cgImage = image.cgImage else {
            throw MLError.inferenceFailed("Provided UIImage does not contain a valid CGImage.")
        }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
                if let error = error {
                    continuation.resume(throwing: MLError.inferenceFailed(error.localizedDescription))
                    return
                }
                
                guard let self = self else {
                    continuation.resume(throwing: MLError.inferenceFailed("MLService was deallocated."))
                    return
                }
                
                do {
                    let result = try self.parseClassificationResults(request: request)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Image pre-processing is BAKED INTO the model (scale=1/127.5, bias=[-1,-1,-1])
            // Do NOT resize or normalize in Swift; pass the image as-is to Vision.
            request.imageCropAndScaleOption = .centerCrop
            
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: orientation,
                options: [:]
            )
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: MLError.inferenceFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Result Parsing
    
    private func parseClassificationResults(request: VNRequest) throws -> ClassificationResult {
        var predictions: [(disease: DiseaseType, confidence: Float)] = []
        
        // 1. Standard Vision classification observations
        if let observations = request.results as? [VNClassificationObservation], !observations.isEmpty {
            for obs in observations {
                if let disease = DiseaseType(rawValue: obs.identifier) {
                    predictions.append((disease: disease, confidence: obs.confidence))
                }
            }
        }
        // 2. Fallback: Direct MultiArray or FeatureValue output indexed 0..4
        else if let featureObs = request.results?.first as? VNCoreMLFeatureValueObservation,
                let multiArray = featureObs.featureValue.multiArrayValue {
            for index in 0..<min(Self.orderedClasses.count, multiArray.count) {
                let conf = multiArray[index].floatValue
                predictions.append((disease: Self.orderedClasses[index], confidence: conf))
            }
        }
        
        guard !predictions.isEmpty else {
            throw MLError.invalidResult
        }
        
        // Sort descending by confidence
        predictions.sort(by: { $0.confidence > $1.confidence })
        
        guard let top = predictions.first else {
            throw MLError.invalidResult
        }
        
        // Take top 3 predictions
        let top3 = Array(predictions.prefix(3))
        
        return ClassificationResult(
            disease: top.disease,
            confidence: top.confidence,
            topPredictions: top3
        )
    }
}

// MARK: - CGImagePropertyOrientation Helper

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
