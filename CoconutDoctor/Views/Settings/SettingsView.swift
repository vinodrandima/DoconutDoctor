//
//  SettingsView.swift
//  CoconutDoctor
//
//  Bottom navigation Settings tab combining Account, Cloud Sync, Biometric Security, and Diagnostics.
//

import SwiftUI

public struct SettingsView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var showLoginSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Section: User Account
                accountSection
                
                // MARK: - Section: Cloud Synchronization
                cloudSyncSection
                
                // MARK: - Section: Security & Biometrics
                securitySection
                
                // MARK: - Section: Local Core Data Engine
                offlineStorageSection
                
                // MARK: - Section: App & Model Diagnostics
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showLoginSheet) {
                LoginView(authService: dependencies.authService)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var accountSection: some View {
        Section("Account") {
            switch dependencies.authService.authState {
            case .signedIn(let uid):
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.appAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(dependencies.authService.currentUserEmail ?? "Signed In User")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.appHealthy)
                                .frame(width: 6, height: 6)
                            Text("Firebase Cloud Active")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.appHealthy)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("User ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(uid.prefix(16)) + "…")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                Button(role: .destructive) {
                    try? dependencies.authService.signOut()
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                
            case .signedOut, .offline:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        Text("Guest Mode (Offline Ready)")
                            .font(.subheadline.bold())
                    }
                    
                    Text("Sign in with email & password to securely backup and sync your farm diagnosis records to Firebase Firestore.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                Button {
                    showLoginSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "person.badge.key.fill")
                        Text("Sign In or Register")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var cloudSyncSection: some View {
        Section("Cloud Synchronization") {
            let syncManager = dependencies.syncManager
            
            HStack {
                Label {
                    Text("Network Status")
                } icon: {
                    Image(systemName: syncManager.isOnline ? "wifi" : "wifi.slash")
                        .foregroundStyle(syncManager.isOnline ? Color.appHealthy : Color.orange)
                }
                Spacer()
                Text(syncManager.isOnline ? "Online" : "Offline")
                    .foregroundStyle(syncManager.isOnline ? Color.appHealthy : Color.orange)
                    .font(.subheadline.weight(.medium))
            }
            
            HStack {
                Label {
                    Text("Sync State")
                } icon: {
                    Image(systemName: syncManager.status.iconName)
                        .foregroundStyle(syncManager.status.tintColor)
                }
                Spacer()
                Text(syncManager.status.displayText)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            
            if let lastSync = syncManager.lastSyncDate {
                HStack {
                    Text("Last Synchronized")
                    Spacer()
                    Text(lastSync, style: .time)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text("Pending Local Scans")
                Spacer()
                Text("\(syncManager.pendingSyncCount)")
                    .font(.callout.bold())
                    .foregroundStyle(syncManager.pendingSyncCount > 0 ? Color.orange : Color.secondary)
            }
            
            if case .signedIn = dependencies.authService.authState {
                Button {
                    Task {
                        await syncManager.syncNow()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if syncManager.isSyncing {
                            ProgressView()
                                .padding(.trailing, 4)
                            Text("Synchronizing Scans…")
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!syncManager.isOnline || syncManager.isSyncing)
            }
        }
    }
    
    private var securitySection: some View {
        Section("Security & Privacy") {
            let biometricType = dependencies.biometricService.biometricType
            let isAvailable = dependencies.biometricService.canAuthenticate
            
            Toggle(isOn: Binding(
                get: { dependencies.appSettings.isAppLockEnabled },
                set: { newValue in
                    Task {
                        let reason = newValue ? "Confirm identity to enable App Lock" : "Confirm identity to disable App Lock"
                        let (success, _) = await dependencies.biometricService.authenticate(reason: reason)
                        if success {
                            await MainActor.run {
                                dependencies.appSettings.isAppLockEnabled = newValue
                            }
                        }
                    }
                }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(biometricType == .none ? "Device Passcode Lock" : "\(biometricType.rawValue) App Lock")
                            .font(.body)
                        Text(biometricType == .none ? "Unlock using device passcode" : "Unlock using \(biometricType.rawValue) or device passcode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: biometricType.iconName)
                        .foregroundStyle(dependencies.appSettings.isAppLockEnabled ? Color.appAccent : .secondary)
                }
            }
            .disabled(!isAvailable)
            
            if !isAvailable {
                Text("Biometrics or device passcode not configured. Set up a passcode in iOS Settings to enable app lock.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            
            Toggle(isOn: Binding(
                get: { dependencies.appSettings.isAccountLockEnabled },
                set: { dependencies.appSettings.isAccountLockEnabled = $0 }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protect History Deletion")
                            .font(.body)
                        Text("Require biometric confirmation before clearing scan history")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.rectangle.stack")
                        .foregroundStyle(dependencies.appSettings.isAccountLockEnabled ? Color.appAccent : .secondary)
                }
            }
            .disabled(!isAvailable)
        }
    }
    
    private var offlineStorageSection: some View {
        Section("Offline-First Storage") {
            HStack(spacing: 12) {
                Image(systemName: "internaldrive.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appAccent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Core Data Local Engine")
                        .font(.subheadline.weight(.semibold))
                    Text("Diagnoses, photos, and GPS coords are stored immediately on device. You can diagnose leaves offline in the field.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private var aboutSection: some View {
        Section("About CoconutDoctor") {
            HStack {
                Text("App Version")
                Spacer()
                Text("1.0.0 (Build 1)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Classifier AI")
                Spacer()
                Text("MobileNetV2 (98.4% Acc)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Target Disease Classes")
                Spacer()
                Text("Bud Rot, Blight, Whitefly")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .withDependencies(.shared)
}
