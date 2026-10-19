//
//  ResultView.swift
//  CoconutDoctor
//
//  Display screen for on-device disease diagnosis results, confidence metrics, and top-3 breakdown.
//

import SwiftUI

public struct ResultView: View {
    public let result: ClassificationResult
    public let image: UIImage?
    public let onScanAgain: () -> Void
    
    @State private var showTreatmentStubAlert = false
    
    public init(
        result: ClassificationResult,
        image: UIImage? = nil,
        onScanAgain: @escaping () -> Void
    ) {
        self.result = result
        self.image = image
        self.onScanAgain = onScanAgain
    }
    
    private var isHealthy: Bool {
        result.disease == .healthy
    }
    
    private var primaryColor: Color {
        isHealthy ? .diseaseHealthy : result.disease.themeColor
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Leaf Image Preview (if provided)
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(primaryColor.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                }
                
                // MARK: - Primary Disease Hero Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(primaryColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: result.disease.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(primaryColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text(result.disease.displayName)
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundStyle(isHealthy ? Color.diseaseHealthy : .primary)
                        
                        Text(String(format: "%.0f%% Confidence", result.confidence * 100))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(primaryColor)
                    }
                    
                    Text(isHealthy ? "No symptoms of major palm diseases detected." : "Symptoms detected matching \(result.disease.displayName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isHealthy ? Color.diseaseHealthy.opacity(0.08) : Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(primaryColor.opacity(0.25), lineWidth: 1.5)
                )
                .padding(.horizontal)
                
                // MARK: - Top-3 Predictions Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Top Diagnosis Breakdown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    VStack(spacing: 14) {
                        ForEach(Array(result.topPredictions.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 6) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Text("\(index + 1).")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.secondary)
                                        
                                        Image(systemName: item.disease.iconName)
                                            .font(.caption)
                                            .foregroundStyle(item.disease.themeColor)
                                        
                                        Text(item.disease.displayName)
                                            .font(.subheadline.weight(index == 0 ? .semibold : .regular))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f%%", item.confidence * 100))
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(item.disease.themeColor)
                                }
                                
                                // Styled horizontal progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(item.disease.themeColor)
                                            .frame(
                                                width: max(8, geo.size.width * CGFloat(min(max(item.confidence, 0), 1))),
                                                height: 8
                                            )
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)
                
                // MARK: - Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showTreatmentStubAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "cross.case.fill")
                            Text("View Treatment Advice")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(primaryColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    Button {
                        onScanAgain()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Scan Another Leaf")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
        .navigationTitle("Diagnosis Result")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Treatment Advice", isPresented: $showTreatmentStubAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Detailed trilingual (Sinhala / Tamil / English) treatment plans for \(result.disease.displayName) will be connected in Step 4.")
        }
    }
}

#Preview("ResultView - Disease") {
    NavigationStack {
        ResultView(
            result: ClassificationResult(
                disease: .budRot,
                confidence: 0.94,
                topPredictions: [
                    (disease: .budRot, confidence: 0.94),
                    (disease: .leafRot, confidence: 0.04),
                    (disease: .stemBleeding, confidence: 0.02)
                ]
            ),
            onScanAgain: {}
        )
    }
}

#Preview("ResultView - Healthy") {
    NavigationStack {
        ResultView(
            result: ClassificationResult(
                disease: .healthy,
                confidence: 0.985,
                topPredictions: [
                    (disease: .healthy, confidence: 0.985),
                    (disease: .greyLeafSpot, confidence: 0.01),
                    (disease: .leafRot, confidence: 0.005)
                ]
            ),
            onScanAgain: {}
        )
    }
}
