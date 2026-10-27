//
//  RootGateView.swift
//  CoconutDoctor
//
//  Security root gate coordinating app-wide biometric lock, background transitions,
//  and cold-start verification.
//

import SwiftUI

public struct RootGateView: View {
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var biometricService: BiometricAuthService
    let initialTab: AppTab
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked: Bool
    
    public init(
        appSettings: AppSettings,
        biometricService: BiometricAuthService,
        initialTab: AppTab = .detect
    ) {
        self.appSettings = appSettings
        self.biometricService = biometricService
        self.initialTab = initialTab
        
        // Cold start lock evaluation: if app lock is enabled or -locked passed, start locked
        let forceLocked = ProcessInfo.processInfo.arguments.contains("-locked")
        let shouldStartLocked = (appSettings.isAppLockEnabled || forceLocked) && !ProcessInfo.processInfo.arguments.contains("-nolock")
        _isUnlocked = State(initialValue: !shouldStartLocked)
    }
    
    public var body: some View {
        ZStack {
            // Main app interface
            MainTabView(initialTab: initialTab)
                .opacity(isLocked ? 0 : 1)
            
            // Full-screen biometric lock screen overlay
            if isLocked {
                LockScreenView(
                    biometricService: biometricService,
                    onUnlockRequest: {
                        await requestUnlock()
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLocked)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isLocked: Bool {
        (appSettings.isAppLockEnabled || ProcessInfo.processInfo.arguments.contains("-locked")) && !isUnlocked
    }
    
    // MARK: - Scene Transitions
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // When app moves to background, instantly re-lock if lock is enabled
            if appSettings.isAppLockEnabled {
                isUnlocked = false
            }
        case .active:
            // Returning from background or switcher
            if appSettings.isAppLockEnabled && !isUnlocked {
                // LockScreenView auto-prompts on appear
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Authentication Request
    
    private func requestUnlock() async -> Bool {
        let (success, _) = await biometricService.authenticate(
            reason: "Unlock CoconutDoctor to access leaf diagnosis records"
        )
        if success {
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.isUnlocked = true
                }
            }
        }
        return success
    }
}
