//
//  FarmMapView.swift
//  CoconutDoctor
//
//  Interactive MapKit farm map displaying geo-tagged disease detection pins,
//  user GPS location, callout cards, and filter controls.
//

import SwiftUI
import MapKit

public struct FarmMapView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel: MapViewModel
    @State private var navigateToDetail: ScanRecord?
    
    public init(viewModel: MapViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: MapViewModel())
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Interactive MapKit Map
                Map(position: $viewModel.cameraPosition) {
                    // Show live user location blue dot
                    UserAnnotation()
                    
                    // Geo-tagged scan disease pins
                    ForEach(viewModel.filteredScans) { scan in
                        if let coordinate = scan.coordinate {
                            Annotation(
                                "",
                                coordinate: coordinate,
                                anchor: .bottom
                            ) {
                                DiseasePinView(
                                    scan: scan,
                                    isSelected: viewModel.selectedScan?.id == scan.id
                                )
                                .onTapGesture {
                                    viewModel.selectScan(scan)
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                }
                
                // MARK: - Overlays & Filters
                VStack(spacing: 12) {
                    // Disease filter chips bar
                    diseaseFilterBar
                    
                    // Location permission banner (if not authorized)
                    if !viewModel.locationManager.isLocationAuthorized {
                        locationPermissionBanner
                    }
                    
                    Spacer()
                    
                    // Empty state overlay if no scans
                    if viewModel.geoScans.isEmpty && !viewModel.isLoading {
                        emptyScansOverlay
                    }
                    
                    // Selected Pin Callout Card
                    if let selected = viewModel.selectedScan {
                        scanCalloutCard(selected)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 560 : .infinity)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .navigationTitle("Farm Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.fitPins(viewModel.filteredScans)
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                    }
                    .disabled(viewModel.filteredScans.isEmpty)
                }
            }
            .navigationDestination(item: $navigateToDetail) { scan in
                ResultView(
                    result: scan.toClassificationResult(),
                    image: scan.imageThumbnail.flatMap(UIImage.init),
                    isFromHistory: true,
                    onScanAgain: {
                        navigateToDetail = nil
                    }
                )
            }
            .onAppear {
                viewModel.fetchGeoScans()
                if !viewModel.locationManager.isLocationAuthorized {
                    viewModel.locationManager.requestWhenInUseAuthorization()
                }
            }
        }
    }
    
    // MARK: - Disease Filter Bar
    
    private var diseaseFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Chip
                filterChip(title: "All (\(viewModel.geoScans.count))", isSelected: viewModel.selectedDiseaseFilter == nil) {
                    viewModel.selectedDiseaseFilter = nil
                    viewModel.fitPins(viewModel.geoScans)
                }
                
                // Per-disease chips
                ForEach(DiseaseType.allCases) { disease in
                    let count = viewModel.geoScans.filter { $0.disease == disease }.count
                    filterChip(
                        title: "\(disease.displayName) (\(count))",
                        color: disease.themeColor,
                        isSelected: viewModel.selectedDiseaseFilter == disease
                    ) {
                        viewModel.selectedDiseaseFilter = (viewModel.selectedDiseaseFilter == disease) ? nil : disease
                        viewModel.fitPins(viewModel.filteredScans)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private func filterChip(
        title: String,
        color: Color = .primary,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? color.opacity(0.2) : Color(.systemBackground).opacity(0.85))
                .foregroundStyle(isSelected ? color : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? color : Color(.separator), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Location Permission Banner
    
    private var locationPermissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Location Access Disabled")
                    .font(.subheadline.bold())
                Text("Enable GPS in Settings to see your position on the plantation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Enable") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Empty Scans Overlay
    
    private var emptyScansOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44))
                .foregroundStyle(Color.appAccent)
            
            VStack(spacing: 4) {
                Text("No geo-tagged scans yet")
                    .font(.headline)
                Text("Detected scans with location will appear here across your farm.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Selected Scan Callout Card
    
    private func scanCalloutCard(_ scan: ScanRecord) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Leaf thumbnail or disease icon
                if let data = scan.imageThumbnail, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(scan.disease.themeColor.opacity(0.4), lineWidth: 1.5)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(scan.disease.themeColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: scan.disease.iconName)
                            .font(.title2)
                            .foregroundStyle(scan.disease.themeColor)
                    }
                }
                
                // Disease info & date
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(scan.disease.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(String(format: "%.0f%%", scan.confidence * 100))
                            .font(.caption2.bold())
                            .foregroundStyle(scan.disease.themeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(scan.disease.themeColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    Text(scan.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let lat = scan.latitude, let lon = scan.longitude {
                        Text(String(format: "GPS: %.4f°N, %.4f°E", lat, lon))
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Close button
                Button {
                    withAnimation {
                        viewModel.selectScan(nil)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Detail action button
            Button {
                navigateToDetail = scan
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cross.case.fill")
                    Text("View Diagnosis & Treatment Advice")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(scan.disease.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(scan.disease.themeColor.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 5)
    }
}

// MARK: - Disease Pin View

public struct DiseasePinView: View {
    public let scan: ScanRecord
    public let isSelected: Bool
    
    public var body: some View {
        VStack(spacing: 0) {
            // Pin bubble
            ZStack {
                Circle()
                    .fill(scan.disease.themeColor)
                    .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                    .shadow(color: scan.disease.themeColor.opacity(0.4), radius: isSelected ? 8 : 4, x: 0, y: 3)
                
                Circle()
                    .stroke(.white, lineWidth: isSelected ? 2.5 : 2)
                    .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                
                Image(systemName: scan.disease.iconName)
                    .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Pin stem pointer
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption2)
                .foregroundStyle(scan.disease.themeColor)
                .offset(y: -2)
            
            // Optional callout preview badge when selected
            if isSelected {
                Text(scan.disease.displayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThickMaterial)
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(scan.disease.themeColor, lineWidth: 1))
                    .shadow(radius: 2)
                    .offset(y: 2)
            }
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    FarmMapView(
        viewModel: MapViewModel(
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
