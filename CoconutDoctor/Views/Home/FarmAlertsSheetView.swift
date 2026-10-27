//
//  FarmAlertsSheetView.swift
//  CoconutDoctor
//
//  Notification Center sheet for Home Dashboard displaying active grove disease alerts,
//  scheduled treatment check-ins, and inspection reminders.
//

import SwiftUI

public struct FarmAlertsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies
    
    public let diseaseAlert: DiseaseAlert?
    public let onNavigateToDetect: () -> Void
    
    @State private var didSendTest: Bool = false
    
    public init(
        diseaseAlert: DiseaseAlert? = nil,
        onNavigateToDetect: @escaping () -> Void = {}
    ) {
        self.diseaseAlert = diseaseAlert
        self.onNavigateToDetect = onNavigateToDetect
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Section 1: Active Grove Alerts
                Section {
                    if let alert = diseaseAlert {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.red)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(alert.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text("Urgent")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.red.opacity(0.12))
                                            .foregroundStyle(Color.red)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Text(alert.message)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "cross.case.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.appAccent)
                                Text(alert.recommendation)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .padding(10)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button {
                                dismiss()
                                onNavigateToDetect()
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.viewfinder")
                                    Text("Inspect Adjacent Palms Now")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 6)
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title2)
                                .foregroundStyle(Color.appHealthy)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No Active Outbreak Alerts")
                                    .font(.headline)
                                Text("Your grove has no contagious clusters detected. Keep up routine scans.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                } header: {
                    Text("Urgent Field Alerts")
                }
                
                // MARK: - Section 2: Scheduled Reminders
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appAccent.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(Color.appAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Grove Inspection")
                                .font(.subheadline.bold())
                            Text("Every Sunday at 8:00 AM • Routine frond check")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Active")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appHealthy)
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.diseaseBudRot.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "cross.case.fill")
                                .foregroundStyle(Color.diseaseBudRot)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("7-Day Treatment Check-ins")
                                .font(.subheadline.bold())
                            Text("Triggered automatically after diagnosing leaf disease")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Ready")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Scheduled Protocols")
                }
                
                // MARK: - Section 3: Notification Actions
                Section {
                    Button {
                        Task {
                            let sent = await dependencies.notificationService.sendTestNotification()
                            if sent {
                                withAnimation { didSendTest = true }
                            }
                        }
                    } label: {
                        HStack {
                            Label(
                                didSendTest ? "Test Alert Sent!" : "Send Test Notification",
                                systemImage: didSendTest ? "checkmark.circle.fill" : "bell.and.waveform.fill"
                            )
                            .foregroundStyle(didSendTest ? Color.appHealthy : Color.primary)
                            
                            Spacer()
                            
                            if didSendTest {
                                Text("Check top banner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Diagnostics")
                } footer: {
                    Text("You can fine-tune notification preferences under Settings > Field Notifications.")
                        .font(.caption2)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Farm Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
