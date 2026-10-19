//
//  DependencyContainer.swift
//  CoconutDoctor
//
//  Dependency Injection container for app singletons and protocols.
//

import SwiftUI

public final class DependencyContainer: @unchecked Sendable {
    /// Default production container using real on-device MLService and ScanRepository
    public static let shared = DependencyContainer(
        mlService: MLService(),
        scanRepository: ScanRepository()
    )
    
    /// Lightweight container for SwiftUI Previews and testing (uses MockMLService)
    public static let preview = DependencyContainer(
        mlService: MockMLService()
    )
    
    public let mlService: MLServiceProtocol
    public let scanRepository: ScanRepositoryProtocol
    
    public init(
        mlService: MLServiceProtocol = MLService(),
        scanRepository: ScanRepositoryProtocol = ScanRepository()
    ) {
        self.mlService = mlService
        self.scanRepository = scanRepository
    }
    
    /// Convenience initializer allowing mock ML service injection for previews/tests
    public convenience init(mockMLResult: ClassificationResult) {
        self.init(mlService: MockMLService(mockResult: mockMLResult))
    }
}

// MARK: - SwiftUI Environment Integration

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = .shared
}

extension EnvironmentValues {
    public var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

extension View {
    /// Injects a custom DependencyContainer into the view hierarchy
    public func withDependencies(_ container: DependencyContainer) -> some View {
        environment(\.dependencies, container)
    }
}
