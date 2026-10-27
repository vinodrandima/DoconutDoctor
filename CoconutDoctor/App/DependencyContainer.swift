//
//  DependencyContainer.swift
//  CoconutDoctor
//
//  Dependency Injection container for app singletons and protocols.
//

import SwiftUI
import FirebaseCore

public final class DependencyContainer: @unchecked Sendable {
    /// Default production container using real on-device MLService, CoreDataScanRepository, Cloud Sync, and Biometric Auth
    @MainActor
    public static let shared: DependencyContainer = {
        let ml = MLService()
        let scanRepo = CoreDataScanRepository()
        let treat = TreatmentService()
        let loc = LocationManager()
        let auth = AuthService()
        let firestore = FirestoreScanRepository()
        let sync = SyncManager(coreDataRepo: scanRepo, firestoreRepo: firestore, authService: auth)
        let biometric = BiometricAuthService()
        let settings = AppSettings()
        let notifications = NotificationService()
        return DependencyContainer(
            mlService: ml,
            scanRepository: scanRepo,
            treatmentService: treat,
            locationManager: loc,
            authService: auth,
            syncManager: sync,
            biometricService: biometric,
            appSettings: settings,
            notificationService: notifications
        )
    }()
    
    /// Lightweight container for SwiftUI Previews and testing (uses MockMLService and in-memory CoreData)
    @MainActor
    public static let preview: DependencyContainer = {
        let ml = MockMLService()
        let scanRepo = CoreDataScanRepository(inMemory: true)
        let treat = TreatmentService()
        let loc = LocationManager()
        let auth = AuthService()
        let firestore = FirestoreScanRepository()
        let sync = SyncManager(coreDataRepo: scanRepo, firestoreRepo: firestore, authService: auth)
        let biometric = BiometricAuthService()
        let settings = AppSettings()
        let notifications = NotificationService()
        return DependencyContainer(
            mlService: ml,
            scanRepository: scanRepo,
            treatmentService: treat,
            locationManager: loc,
            authService: auth,
            syncManager: sync,
            biometricService: biometric,
            appSettings: settings,
            notificationService: notifications
        )
    }()
    
    public let mlService: MLServiceProtocol
    public let scanRepository: ScanRepositoryProtocol
    public let treatmentService: TreatmentServiceProtocol
    public let locationManager: LocationManager
    public let authService: AuthService
    public let syncManager: SyncManager
    public let biometricService: BiometricAuthService
    public let appSettings: AppSettings
    public let notificationService: NotificationService
    
    @MainActor
    public init(
        mlService: MLServiceProtocol? = nil,
        scanRepository: ScanRepositoryProtocol? = nil,
        treatmentService: TreatmentServiceProtocol? = nil,
        locationManager: LocationManager? = nil,
        authService: AuthService? = nil,
        syncManager: SyncManager? = nil,
        biometricService: BiometricAuthService? = nil,
        appSettings: AppSettings? = nil,
        notificationService: NotificationService? = nil
    ) {
        let repo = scanRepository ?? CoreDataScanRepository()
        self.mlService = mlService ?? MLService()
        self.scanRepository = repo
        self.treatmentService = treatmentService ?? TreatmentService()
        self.locationManager = locationManager ?? LocationManager()
        let auth = authService ?? AuthService()
        self.authService = auth
        self.syncManager = syncManager ?? SyncManager(
            coreDataRepo: repo,
            firestoreRepo: FirestoreScanRepository(),
            authService: auth
        )
        self.biometricService = biometricService ?? BiometricAuthService()
        self.appSettings = appSettings ?? AppSettings()
        self.notificationService = notificationService ?? NotificationService()
    }
    
    /// Convenience initializer allowing mock ML service injection for previews/tests
    @MainActor
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
    @MainActor static var defaultValue: DependencyContainer {
        DependencyContainer.shared
    }
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
