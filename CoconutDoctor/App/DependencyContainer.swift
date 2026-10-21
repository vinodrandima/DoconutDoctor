//
//  DependencyContainer.swift
//  CoconutDoctor
//
//  Dependency Injection container for app singletons and protocols.
//

import SwiftUI

public final class DependencyContainer: @unchecked Sendable {
    /// Default production container using real on-device MLService and CoreDataScanRepository
    public static let shared = DependencyContainer(
        mlService: MLService(),
        scanRepository: CoreDataScanRepository(),
        treatmentService: TreatmentService(),
        locationManager: LocationManager()
    )
    
    /// Lightweight container for SwiftUI Previews and testing (uses MockMLService and in-memory CoreData)
    public static let preview = DependencyContainer(
        mlService: MockMLService(),
        scanRepository: CoreDataScanRepository(inMemory: true),
        treatmentService: TreatmentService(),
        locationManager: LocationManager()
    )
    
    public let mlService: MLServiceProtocol
    public let scanRepository: ScanRepositoryProtocol
    public let treatmentService: TreatmentServiceProtocol
    public let locationManager: LocationManager
    
    public init(
        mlService: MLServiceProtocol = MLService(),
        scanRepository: ScanRepositoryProtocol = CoreDataScanRepository(),
        treatmentService: TreatmentServiceProtocol = TreatmentService(),
        locationManager: LocationManager = LocationManager()
    ) {
        self.mlService = mlService
        self.scanRepository = scanRepository
        self.treatmentService = treatmentService
        self.locationManager = locationManager
    }
    
    /// Convenience initializer allowing mock ML service injection for previews/tests
    public convenience init(mockMLResult: ClassificationResult) {
        self.init(
            mlService: MockMLService(mockResult: mockMLResult),
            scanRepository: CoreDataScanRepository(inMemory: true),
            treatmentService: TreatmentService(),
            locationManager: LocationManager()
        )
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
