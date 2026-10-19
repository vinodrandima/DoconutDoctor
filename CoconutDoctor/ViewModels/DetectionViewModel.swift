//
//  DetectionViewModel.swift
//  CoconutDoctor
//
//  ViewModel coordinating image selection, camera capture, and on-device disease diagnosis.
//

import UIKit
import SwiftUI
import Combine

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
    
    public init(mlService: MLServiceProtocol? = nil) {
        self.mlService = mlService ?? DependencyContainer.shared.mlService
    }
    
    public func selectImage(_ image: UIImage) {
        self.selectedImage = image
        self.state = .idle
        self.errorMessage = nil
        self.showErrorAlert = false
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
            } catch {
                let message = error.localizedDescription
                self.state = .error(message)
                self.presentError(message)
            }
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
