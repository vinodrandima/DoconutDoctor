//
//  ScanRepository.swift
//  CoconutDoctor
//
//  Offline-first repository interface and store for coconut leaf scan records.
//

import Foundation

public protocol ScanRepositoryProtocol: Sendable {
    func fetchAllScans() async throws -> [ScanRecord]
    func saveScan(_ scan: ScanRecord) async throws
    func deleteScan(id: UUID) async throws
    func clearAll() async throws
}

/// In-memory repository implementation (will be backed by Core Data in subsequent steps).
public actor ScanRepository: ScanRepositoryProtocol {
    private var records: [ScanRecord] = []
    
    public init(initialRecords: [ScanRecord] = []) {
        self.records = initialRecords
    }
    
    public func fetchAllScans() async throws -> [ScanRecord] {
        return records.sorted(by: { $0.date > $1.date })
    }
    
    public func saveScan(_ scan: ScanRecord) async throws {
        records.removeAll(where: { $0.id == scan.id })
        records.append(scan)
    }
    
    public func deleteScan(id: UUID) async throws {
        records.removeAll(where: { $0.id == id })
    }
    
    public func clearAll() async throws {
        records.removeAll()
    }
}
