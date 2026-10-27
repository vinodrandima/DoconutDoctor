//
//  SyncManager.swift
//  CoconutDoctor
//
//  Non-blocking background synchronizer bridging offline Core Data (source of truth)
//  with Cloud Firestore when authenticated and online.
//

import Foundation
import SwiftUI
import Combine
import Network
import FirebaseFirestore

public enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case synced(Date?)
    case offline
    case guest
    case error(String)
    
    public var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing…"
        case .synced(let date):
            if let date = date {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
            } else {
                return "Synced"
            }
        case .offline:
            return "Offline Mode"
        case .guest:
            return "Guest Mode"
        case .error:
            return "Sync Error"
        }
    }
    
    public var iconName: String {
        switch self {
        case .idle:
            return "cloud"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud.fill"
        case .offline:
            return "wifi.slash"
        case .guest:
            return "person.crop.circle"
        case .error:
            return "exclamationmark.icloud.fill"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .idle:
            return .secondary
        case .syncing:
            return .appAccent
        case .synced:
            return .appHealthy
        case .offline:
            return .orange
        case .guest:
            return .secondary
        case .error:
            return .red
        }
    }
}

@MainActor
public final class SyncManager: ObservableObject, @unchecked Sendable {
    @Published public private(set) var status: SyncStatus = .idle
    @Published public private(set) var isOnline: Bool = true
    @Published public private(set) var lastSyncDate: Date? = nil
    @Published public private(set) var pendingSyncCount: Int = 0
    @Published public private(set) var isSyncing: Bool = false
    
    private let coreDataRepo: ScanRepositoryProtocol
    private let firestoreRepo: FirestoreScanRepository
    private let authService: AuthService
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.coconutdoctor.sync.network")
    private var remoteListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        coreDataRepo: ScanRepositoryProtocol,
        firestoreRepo: FirestoreScanRepository,
        authService: AuthService
    ) {
        self.coreDataRepo = coreDataRepo
        self.firestoreRepo = firestoreRepo
        self.authService = authService
        
        setupNetworkMonitoring()
        setupAuthObserver()
    }
    
    public convenience init(
        coreDataRepo: ScanRepositoryProtocol,
        authService: AuthService
    ) {
        self.init(
            coreDataRepo: coreDataRepo,
            firestoreRepo: FirestoreScanRepository(),
            authService: authService
        )
    }
    
    deinit {
        networkMonitor.cancel()
        remoteListener?.remove()
    }
    
    // MARK: - Setup & Observers
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                let reachable = path.status == .satisfied
                let wasOffline = !self.isOnline
                self.isOnline = reachable
                
                if reachable {
                    if wasOffline {
                        print("🌐 Network reconnected. Evaluating sync trigger.")
                        await self.syncNow()
                    }
                } else {
                    self.status = .offline
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func setupAuthObserver() {
        authService.$authState
            .sink { [weak self] state in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.handleAuthStateChange(state)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .signedIn(let uid):
            firestoreRepo.currentUID = uid
            attachRemoteListener(for: uid)
            Task {
                await self.syncNow()
            }
            
        case .signedOut:
            detachRemoteListener()
            firestoreRepo.currentUID = nil
            status = .guest
            
        case .offline:
            detachRemoteListener()
            firestoreRepo.currentUID = nil
            status = .guest
        }
        
        refreshPendingCount()
    }
    
    // MARK: - Remote Firestore Listener
    
    private func attachRemoteListener(for uid: String) {
        detachRemoteListener()
        
        remoteListener = firestoreRepo.listenToRemoteScans(uid: uid) { [weak self] remoteScans in
            Task { @MainActor in
                guard let self = self else { return }
                await self.mergeRemoteScansIntoCoreData(remoteScans)
            }
        }
    }
    
    private func detachRemoteListener() {
        remoteListener?.remove()
        remoteListener = nil
    }
    
    private func mergeRemoteScansIntoCoreData(_ remoteScans: [ScanRecord]) async {
        for scan in remoteScans {
            do {
                try await coreDataRepo.saveFromRemote(scan)
            } catch {
                print("⚠️ Failed to merge remote scan \(scan.id): \(error)")
            }
        }
        refreshPendingCount()
    }
    
    // MARK: - Public Sync Trigger
    
    public func syncNow() async {
        // Enforce guest / offline restriction: guests never touch Firestore
        guard case .signedIn(let uid) = authService.authState else {
            status = .guest
            refreshPendingCount()
            return
        }
        
        guard isOnline else {
            status = .offline
            refreshPendingCount()
            return
        }
        
        guard !isSyncing else { return }
        
        isSyncing = true
        status = .syncing
        firestoreRepo.currentUID = uid
        
        do {
            // 1. Fetch pending local unsynced scans
            let unsynced = try await coreDataRepo.fetchUnsynced()
            pendingSyncCount = unsynced.count
            
            // 2. Upload local unsynced scans to Firestore
            for scan in unsynced {
                try await firestoreRepo.save(scan)
                try await coreDataRepo.markAsSynced(id: scan.id)
            }
            
            // 3. Pull remote scans from Firestore to ensure two-way synchronization
            let remoteScans = try await firestoreRepo.fetchAll()
            await mergeRemoteScansIntoCoreData(remoteScans)
            
            // 4. Update sync state
            let now = Date()
            lastSyncDate = now
            status = .synced(now)
            pendingSyncCount = 0
            isSyncing = false
            
        } catch {
            print("❌ Cloud sync failed: \(error.localizedDescription)")
            status = .error(error.localizedDescription)
            isSyncing = false
            refreshPendingCount()
        }
    }
    
    public func refreshPendingCount() {
        Task {
            do {
                let unsynced = try await coreDataRepo.fetchUnsynced()
                self.pendingSyncCount = unsynced.count
            } catch {
                self.pendingSyncCount = 0
            }
        }
    }
    
    /// Triggered after a scan is saved locally in Core Data to sync immediately if online & signed in
    public func notifyLocalScanSaved() {
        refreshPendingCount()
        if case .signedIn = authService.authState, isOnline {
            Task {
                await syncNow()
            }
        }
    }
}
