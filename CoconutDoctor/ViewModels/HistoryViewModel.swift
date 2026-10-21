//
//  HistoryViewModel.swift
//  CoconutDoctor
//
//  ViewModel managing offline scan history fetching, deletion, and reactive UI updates.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class HistoryViewModel: ObservableObject {
    @Published public var scans: [ScanRecord] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    
    private let scanRepository: ScanRepositoryProtocol
    
    public init(scanRepository: ScanRepositoryProtocol? = nil) {
        self.scanRepository = scanRepository ?? DependencyContainer.shared.scanRepository
    }
    
    public func fetchScans() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let records = try await scanRepository.fetchAll()
                self.scans = records
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load scan history: \(error.localizedDescription)"
                self.showErrorAlert = true
                self.isLoading = false
            }
        }
    }
    
    public func deleteScan(at offsets: IndexSet) {
        let itemsToDelete = offsets.compactMap { index -> ScanRecord? in
            guard index < scans.count else { return nil }
            return scans[index]
        }
        
        // Optimistic UI removal
        scans.remove(atOffsets: offsets)
        
        Task {
            for item in itemsToDelete {
                do {
                    try await scanRepository.delete(id: item.id)
                } catch {
                    self.errorMessage = "Failed to delete scan: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    await self.refreshScansSilently()
                    break
                }
            }
        }
    }
    
    public func deleteScan(id: UUID) {
        scans.removeAll(where: { $0.id == id })
        Task {
            do {
                try await scanRepository.delete(id: id)
            } catch {
                self.errorMessage = "Failed to delete scan: \(error.localizedDescription)"
                self.showErrorAlert = true
                await self.refreshScansSilently()
            }
        }
    }
    
    public func deleteAll() {
        scans.removeAll()
        Task {
            do {
                try await scanRepository.deleteAll()
            } catch {
                self.errorMessage = "Failed to clear history: \(error.localizedDescription)"
                self.showErrorAlert = true
                await self.refreshScansSilently()
            }
        }
    }
    
    private func refreshScansSilently() async {
        if let records = try? await scanRepository.fetchAll() {
            self.scans = records
        }
    }
}
