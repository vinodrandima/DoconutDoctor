//
//  MockMLService.swift
//  CoconutDoctor
//
//  Mock MLService implementation for SwiftUI previews and unit testing.
//

import UIKit

public final class MockMLService: MLServiceProtocol, @unchecked Sendable {
    public var mockResult: ClassificationResult
    public var delaySeconds: TimeInterval
    public var shouldThrowError: MLError?
    
    public init(
        mockResult: ClassificationResult = ClassificationResult(
            disease: .budRot,
            confidence: 0.94,
            topPredictions: [
                (disease: .budRot, confidence: 0.94),
                (disease: .leafRot, confidence: 0.04),
                (disease: .stemBleeding, confidence: 0.02)
            ]
        ),
        delaySeconds: TimeInterval = 1.5,
        shouldThrowError: MLError? = nil
    ) {
        self.mockResult = mockResult
        self.delaySeconds = delaySeconds
        self.shouldThrowError = shouldThrowError
    }
    
    public func classify(image: UIImage) async throws -> ClassificationResult {
        if delaySeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }
        
        if let error = shouldThrowError {
            throw error
        }
        
        return mockResult
    }
}
