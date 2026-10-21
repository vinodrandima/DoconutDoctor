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
    
    // Backwards-compatible aliases
    func fetchAllScans() async throws -> [ScanRecord]
    func saveScan(_ scan: ScanRecord) async throws
    func deleteScan(id: UUID) async throws
    func clearAll() async throws
}

extension ScanRepositoryProtocol {
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
}
