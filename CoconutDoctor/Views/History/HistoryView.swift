//
//  HistoryView.swift
//  CoconutDoctor
//
//  Offline scan history tab displaying past disease diagnoses, thumbnails, and detail views.
//

import SwiftUI

public struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var searchText: String = ""
    @State private var showClearConfirm: Bool = false
    
    public init(viewModel: HistoryViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: HistoryViewModel())
        }
    }
    
    private var filteredScans: [ScanRecord] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.scans
        } else {
            return viewModel.scans.filter { scan in
                scan.disease.displayName.localizedCaseInsensitiveContains(searchText) ||
                scan.diseaseLabel.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.scans.isEmpty {
                    ProgressView("Loading history...")
                } else if viewModel.scans.isEmpty {
                    emptyStateView
                } else {
                    scansListView
                }
            }
            .navigationTitle("Scan History")
            .searchable(text: $searchText, prompt: "Filter by disease name")
            .toolbar {
                if !viewModel.scans.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All Scans", role: .destructive) {
                    viewModel.deleteAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all offline diagnosis records on this device.")
            }
            .alert("History Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred while managing scan history.")
            }
            .onAppear {
                viewModel.fetchScans()
            }
            .refreshable {
                viewModel.fetchScans()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No scans yet", systemImage: "leaf.arrow.triangle.circlepath")
                .foregroundStyle(Color.appAccent)
        } description: {
            Text("Diagnose coconut leaves in the Detect tab. Your scan results, photos, and treatment recommendations will be saved here automatically for offline review.")
                .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Scans List
    
    private var scansListView: some View {
        List {
            ForEach(filteredScans) { scan in
                NavigationLink {
                    HistoryDetailView(scan: scan)
                } label: {
                    scanRow(scan)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: viewModel.deleteScan)
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Row View
    
    private func scanRow(_ scan: ScanRecord) -> some View {
        HStack(spacing: 14) {
            // Thumbnail image or placeholder
            if let thumbnailData = scan.imageThumbnail,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scan.disease.themeColor.opacity(0.4), lineWidth: 1.5)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scan.disease.themeColor.opacity(0.12))
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: scan.disease.iconName)
                        .font(.title2)
                        .foregroundStyle(scan.disease.themeColor)
                }
            }
            
            // Disease details and date
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.disease.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(scan.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let lat = scan.latitude, let lon = scan.longitude {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                        Text(String(format: "%.2f°, %.2f°", lat, lon))
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Confidence Badge
            Text(String(format: "%.0f%%", scan.confidence * 100))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(scan.disease.themeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(scan.disease.themeColor.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(scan.disease.themeColor.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - History Detail View (Reuses ResultView + TreatmentView)

private struct HistoryDetailView: View {
    let scan: ScanRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ResultView(
            result: scan.toClassificationResult(),
            image: scan.imageThumbnail.flatMap(UIImage.init),
            isFromHistory: true,
            onScanAgain: {
                dismiss()
            }
        )
    }
}

#Preview("HistoryView - Empty") {
    HistoryView(viewModel: HistoryViewModel(scanRepository: ScanRepository()))
}

#Preview("HistoryView - With Records") {
    HistoryView(
        viewModel: HistoryViewModel(
            scanRepository: ScanRepository(initialRecords: [
                ScanRecord(
                    disease: .budRot,
                    confidence: 0.94,
                    date: Date(),
                    latitude: 7.4863,
                    longitude: 80.3623
                ),
                ScanRecord(
                    disease: .healthy,
                    confidence: 0.98,
                    date: Date().addingTimeInterval(-3600),
                    latitude: 7.4912,
                    longitude: 80.3541
                )
            ])
        )
    )
}
