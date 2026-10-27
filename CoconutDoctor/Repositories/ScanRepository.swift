//
//  ScanRepository.swift
//  CoconutDoctor
//
//  Offline-first repository protocol and in-memory mock store for coconut leaf scan records.
//

import Foundation

public protocol ScanRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [ScanRecord]
    func save(_ scan: ScanRecord) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
    
    // Cloud sync extensions
    func fetchUnsynced() async throws -> [ScanRecord]
    func markAsSynced(id: UUID) async throws
    func saveFromRemote(_ scan: ScanRecord) async throws
    
    // Backwards-compatible aliases
    func fetchAllScans() async throws -> [ScanRecord]
    func saveScan(_ scan: ScanRecord) async throws
    func deleteScan(id: UUID) async throws
    func clearAll() async throws
}

extension ScanRepositoryProtocol {
    public func fetchUnsynced() async throws -> [ScanRecord] {
        let all = try await fetchAll()
        return all.filter { !$0.isSynced }
    }
    
    public func markAsSynced(id: UUID) async throws {
        // Default no-op for generic repositories
    }
    
    public func saveFromRemote(_ scan: ScanRecord) async throws {
        var copy = scan
        copy.isSynced = true
        try await save(copy)
    }
    
    public func fetchAllScans() async throws -> [ScanRecord] {
        try await fetchAll()
    }
    
    public func saveScan(_ scan: ScanRecord) async throws {
        try await save(scan)
    }
    
    public func deleteScan(id: UUID) async throws {
        try await delete(id: id)
    }
    
    public func clearAll() async throws {
        try await deleteAll()
    }
}

/// In-memory repository implementation (used for previews, tests, and mock verification).
public actor ScanRepository: ScanRepositoryProtocol {
    private var records: [ScanRecord] = []
    
    public init(initialRecords: [ScanRecord] = []) {
        self.records = initialRecords
    }
    
    public func fetchAll() async throws -> [ScanRecord] {
        return records.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    public func save(_ scan: ScanRecord) async throws {
        records.removeAll(where: { $0.id == scan.id })
        records.append(scan)
    }
    
    public func delete(id: UUID) async throws {
        records.removeAll(where: { $0.id == id })
    }
    
    public func deleteAll() async throws {
        records.removeAll()
    }
    
    public func fetchUnsynced() async throws -> [ScanRecord] {
        return records.filter { !$0.isSynced }
    }
    
    public func markAsSynced(id: UUID) async throws {
        if let idx = records.firstIndex(where: { $0.id == id }) {
            records[idx].isSynced = true
        }
    }
    
    public func saveFromRemote(_ scan: ScanRecord) async throws {
        var copy = scan
        copy.isSynced = true
        records.removeAll(where: { $0.id == copy.id })
        records.append(copy)
    }
}
