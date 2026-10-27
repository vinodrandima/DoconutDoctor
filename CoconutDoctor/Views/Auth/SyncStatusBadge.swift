//
//  SyncStatusBadge.swift
//  CoconutDoctor
//
//  Navigation bar Settings button, status indicators, and comprehensive Settings & Account sheet.
//

import SwiftUI

/// Clean Settings gear button for navigation bars with subtle sync status telemetry.
public struct SettingsButton: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var authService: AuthService
    @State private var showSettingsSheet = false
    
    public init(syncManager: SyncManager, authService: AuthService) {
        self.syncManager = syncManager
        self.authService = authService
    }
    
    public var body: some View {
        Button {
            showSettingsSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 32, height: 32)
                
                // Active sync or offline indicator dot
                if syncManager.isSyncing {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .offset(x: -1, y: 1)
                } else if syncManager.pendingSyncCount > 0 {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .offset(x: -1, y: 1)
                }
            }
        }
        .accessibilityLabel("Settings & Account")
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheetView(syncManager: syncManager, authService: authService)
        }
    }
}

/// Backward compatibility component
public struct SyncStatusBadge: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var authService: AuthService
    
    public init(syncManager: SyncManager, authService: AuthService) {
        self.syncManager = syncManager
        self.authService = authService
    }
    
    public var body: some View {
        SettingsButton(syncManager: syncManager, authService: authService)
    }
}

/// Comprehensive Settings and Account management sheet
public struct SettingsSheetView: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies
    @State private var showLoginSheet = false
    
    public init(syncManager: SyncManager, authService: AuthService) {
        self.syncManager = syncManager
        self.authService = authService
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Section: Account Details
                Section("Account") {
                    switch authService.authState {
                    case .signedIn(let uid):
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appAccent)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.currentUserEmail ?? "Signed In")
                                    .font(.headline)
                                Text("Firebase Cloud Sync Active")
                                    .font(.caption2)
                                    .foregroundStyle(Color.appHealthy)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("Account ID")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(uid.prefix(14)) + "…")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(role: .destructive) {
                            try? authService.signOut()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                        
                    case .signedOut, .offline:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                Text("Guest Mode (Offline Ready)")
                                    .font(.subheadline.bold())
                            }
                            
                            Text("Sign in with email and password to safely backup and synchronize leaf diagnosis records to Firebase Firestore.")
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
                
                // MARK: - Section: Cloud Synchronization
                Section("Cloud Synchronization") {
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
                    
                    if case .signedIn = authService.authState {
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
                                    Text("Synchronizing…")
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
                
                // MARK: - Section: Biometric Security & App Lock
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
                
                // MARK: - Section: Offline & Storage Architecture
                Section("Offline-First Storage") {
                    HStack(spacing: 12) {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(Color.appAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Core Data Local Engine")
                                .font(.subheadline.weight(.medium))
                            Text("Scans, photos, and diagnoses are saved immediately to local on-device SQLite storage.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                // MARK: - Section: App About & Diagnostics
                Section("About CoconutDoctor") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Model Architecture")
                        Spacer()
                        Text("MobileNetV2 (98.4%)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Supported Diseases")
                        Spacer()
                        Text("Bud Rot, Blight, Whitefly")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView(authService: authService)
            }
        }
    }
}

/// Typealias for existing references
public typealias AccountSheetView = SettingsSheetView
