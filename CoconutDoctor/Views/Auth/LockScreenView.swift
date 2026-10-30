//
//  LockScreenView.swift
//  CoconutDoctor
//
//  Full-screen biometric lock overlay requiring Face ID / Touch ID or device passcode
//  to access CoconutDoctor.
//

import SwiftUI
import LocalAuthentication

public struct LockScreenView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var biometricService: BiometricAuthService
    let onUnlockRequest: () async -> Bool
    
    @State private var isAuthenticatingLocally: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(
        biometricService: BiometricAuthService,
        onUnlockRequest: @escaping () async -> Bool
    ) {
        self.biometricService = biometricService
        self.onUnlockRequest = onUnlockRequest
    }
    
    public var body: some View {
        ZStack {
            // Immersive background gradient
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color.appAccent.opacity(0.08),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // MARK: - Logo & Security Badge
                VStack(spacing: 16) {
                    ZStack {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        
                        // Mini padlock badge
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(Color.appAccent)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2.5))
                            .offset(x: 38, y: 38)
                    }
                    .padding(.bottom, 8)
                    
                    Text("CoconutDoctor Locked")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Biometric security is enabled to protect your farm leaf diagnosis history and telemetry.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // MARK: - Error / Status Notice
                if let message = errorMessage ?? biometricService.lastErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.12))
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
                
                // MARK: - Primary Unlock Action
                VStack(spacing: 16) {
                    Button {
                        performUnlock()
                    } label: {
                        HStack(spacing: 10) {
                            if isAuthenticatingLocally || biometricService.isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                                Text("Verifying Identity…")
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: biometricService.biometricType.iconName)
                                    .font(.title3)
                                Text(biometricService.biometricType.unlockButtonTitle)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.appAccent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .disabled(isAuthenticatingLocally || biometricService.isAuthenticating)
                    
                    // Passcode Fallback Prompt
                    if biometricService.biometricType != .none {
                        Button {
                            performUnlock()
                        } label: {
                            Text("Use Device Passcode")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 440 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            // Auto prompt on view appearance unless explicitly suppressed
            if !ProcessInfo.processInfo.arguments.contains("-no-auto-biometric") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    performUnlock()
                }
            }
        }
    }
    
    private func performUnlock() {
        guard !isAuthenticatingLocally else { return }
        isAuthenticatingLocally = true
        errorMessage = nil
        
        Task {
            let success = await onUnlockRequest()
            await MainActor.run {
                self.isAuthenticatingLocally = false
                if !success {
                    if biometricService.lastErrorMessage == nil {
                        self.errorMessage = "Unlock cancelled. Tap above to try again."
                    }
                }
            }
        }
    }
}

#Preview {
    LockScreenView(
        biometricService: BiometricAuthService(),
        onUnlockRequest: { true }
    )
}
