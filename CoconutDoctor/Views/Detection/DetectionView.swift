//
//  DetectionView.swift
//  CoconutDoctor
//
//  Main detection interface supporting camera capture, gallery selection, and on-device analysis.
//

import SwiftUI
import PhotosUI

public struct DetectionView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel: DetectionViewModel
    
    @State private var showCameraSheet = false
    @State private var showGallerySheet = false
    @State private var activeResult: ClassificationResult?
    @State private var cameraUnavailableAlert = false
    @State private var cameraAlertMessage = ""
    
    public init(viewModel: DetectionViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: DetectionViewModel())
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let selectedImage = viewModel.selectedImage {
                    // MARK: - Selected Image Preview & Action
                    imagePreviewContent(selectedImage)
                } else {
                    // MARK: - Empty Capture State
                    emptyStateContent
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 620 : .infinity)
            .frame(maxWidth: .infinity)
            .navigationTitle("CoconutDoctor")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $activeResult) { result in
                ResultView(
                    result: result,
                    image: viewModel.selectedImage,
                    onScanAgain: {
                        activeResult = nil
                        viewModel.reset()
                    }
                )
            }
            // MARK: - Sheets
            .sheet(isPresented: $showCameraSheet) {
                CameraPickerView(selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { newImage in
                        if let img = newImage {
                            viewModel.selectImage(img)
                        }
                    }
                ))
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showGallerySheet) {
                GalleryPickerView(selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { newImage in
                        if let img = newImage {
                            viewModel.selectImage(img)
                        }
                    }
                ))
            }
            // MARK: - Alerts
            .alert("Camera Error", isPresented: $cameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(cameraAlertMessage)
            }
            .alert("Detection Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred during classification.")
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .success(let result) = newState {
                    activeResult = result
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)
                
                // App Emblem
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.appAccent)
                }
                
                VStack(spacing: 10) {
                    Text("Take a photo of a coconut leaf")
                        .font(.system(.title2, design: .rounded).bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Capture clear photos of fronds, leaflets, or stems showing spots, discoloration, or rotting for instant offline diagnosis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Capture / Gallery Buttons
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        captureButton
                        galleryButton
                    }
                    VStack(spacing: 14) {
                        captureButton
                        galleryButton
                    }
                }
                .padding(.horizontal, 28)
                
                // Simulator / Demo Sample Photos
                VStack(spacing: 8) {
                    Text("Or test with simulated leaf samples:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        sampleButton(title: "Bud Rot Sample", color: .diseaseBudRot) {
                            viewModel.selectImage(createSyntheticLeafSample(primary: .diseaseBudRot))
                        }
                        sampleButton(title: "Healthy Leaf", color: .diseaseHealthy) {
                            viewModel.selectImage(createSyntheticLeafSample(primary: .diseaseHealthy))
                        }
                    }
                }
                .padding(.top, 16)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical, 16)
        }
    }
    
    private var captureButton: some View {
        Button {
            handleCameraTap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.headline)
                Text("Capture Photo")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    private var galleryButton: some View {
        Button {
            showGallerySheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.headline)
                Text("Choose from Gallery")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Image Preview & Analysis Card
    
    private func imagePreviewContent(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: horizontalSizeClass == .regular ? 440 : 340)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                
                // Clear / Retake button
                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white, Color.black.opacity(0.6))
                        .padding(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            VStack(spacing: 12) {
                // Primary Analyze Action Button
                Button {
                    viewModel.analyze()
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.state == .analyzing {
                            ProgressView()
                                .tint(.white)
                            Text("Diagnosing On-Device...")
                                .font(.headline)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.headline)
                            Text("Diagnose Disease")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.state == .analyzing ? Color.gray : Color.appAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(viewModel.state == .analyzing)
                
                // Change photo action
                HStack(spacing: 16) {
                    Button("Take Another") {
                        handleCameraTap()
                    }
                    .font(.subheadline.weight(.medium))
                    .disabled(viewModel.state == .analyzing)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Button("Pick From Gallery") {
                        showGallerySheet = true
                    }
                    .font(.subheadline.weight(.medium))
                    .disabled(viewModel.state == .analyzing)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func handleCameraTap() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlertMessage = "Camera hardware is not available on this device (or simulator). Please select a photo from the gallery or tap one of the simulated samples below."
            cameraUnavailableAlert = true
            return
        }
        
        CameraPermission.checkPermission { granted in
            if granted {
                showCameraSheet = true
            } else {
                cameraAlertMessage = "Camera access has been disabled. Please enable camera access in iOS Settings to capture coconut leaves."
                cameraUnavailableAlert = true
            }
        }
    }
    
    private func sampleButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color.opacity(0.12))
                .foregroundStyle(color)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private func createSyntheticLeafSample(primary: Color) -> UIImage {
        let size = CGSize(width: 224, height: 224)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            
            // Draw background leaf green
            let colors = [
                UIColor(red: 0.16, green: 0.45, blue: 0.16, alpha: 1.0).cgColor,
                UIColor(red: 0.22, green: 0.52, blue: 0.20, alpha: 1.0).cgColor
            ] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            if let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 1.0]) {
                cg.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 224, y: 224), options: [])
            }
            
            // Draw disease lesion patch
            let isBudRot = (primary == .diseaseBudRot)
            let spotColor = isBudRot ? UIColor(red: 0.65, green: 0.22, blue: 0.18, alpha: 0.85) : UIColor(red: 0.35, green: 0.70, blue: 0.25, alpha: 0.7)
            cg.setFillColor(spotColor.cgColor)
            cg.fillEllipse(in: CGRect(x: 50, y: 60, width: 120, height: 90))
            
            // Draw leaf veins
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            cg.setLineWidth(2)
            cg.move(to: CGPoint(x: 0, y: 112))
            cg.addLine(to: CGPoint(x: 224, y: 112))
            cg.strokePath()
        }
    }
}

#Preview("DetectionView - Mock") {
    DetectionView(
        viewModel: DetectionViewModel(mlService: MockMLService())
    )
}

#Preview("DetectionView - Production") {
    DetectionView()
}
