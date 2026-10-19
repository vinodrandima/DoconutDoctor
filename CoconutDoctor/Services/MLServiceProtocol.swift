//
//  MLServiceProtocol.swift
//  CoconutDoctor
//
//  Protocol defining the on-device ML inference capability.
//

import UIKit

public protocol MLServiceProtocol: Sendable {
    func classify(image: UIImage) async throws -> ClassificationResult
}
