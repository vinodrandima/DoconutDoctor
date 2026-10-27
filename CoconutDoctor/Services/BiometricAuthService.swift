//
//  BiometricAuthService.swift
//  CoconutDoctor
//
//  Service handling Face ID, Touch ID, and device passcode biometric authentication
//  using the LocalAuthentication framework.
//

import Foundation
import LocalAuthentication
import SwiftUI
import Combine

public enum BiometricType: String, Sendable {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"
    case none = "Passcode"
    
    public var iconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield.fill"
        }
    }
    
    public var unlockButtonTitle: String {
        switch self {
        case .faceID:
            return "Unlock with Face ID"
        case .touchID:
            return "Unlock with Touch ID"
        case .opticID:
            return "Unlock with Optic ID"
        case .none:
            return "Unlock with Passcode"
        }
    }
}

public protocol BiometricAuthServiceProtocol: Sendable {
    var biometricType: BiometricType { get }
    var canAuthenticate: Bool { get }
    func authenticate(reason: String) async -> (success: Bool, error: LAError?)
    func authenticate() async -> Bool
}

@MainActor
public final class BiometricAuthService: ObservableObject, BiometricAuthServiceProtocol, @unchecked Sendable {
    @Published public private(set) var currentBiometricType: BiometricType = .none
    @Published public private(set) var isAuthenticating: Bool = false
    @Published public var lastErrorMessage: String? = nil
    
    public init() {
        self.currentBiometricType = detectBiometricType()
    }
    
    // MARK: - Capabilities Detection
    
    public var biometricType: BiometricType {
        detectBiometricType()
    }
    
    public var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    public var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    private func detectBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Authentication
    
    public func authenticate() async -> Bool {
        let result = await authenticate(reason: "Unlock CoconutDoctor to access leaf diagnosis records")
        return result.success
    }
    
    public func authenticate(reason: String = "Unlock CoconutDoctor") async -> (success: Bool, error: LAError?) {
        guard canAuthenticate else {
            self.lastErrorMessage = "Device passcode or biometrics are not configured on this device."
            return (false, nil)
        }
        
        isAuthenticating = true
        lastErrorMessage = nil
        defer { isAuthenticating = false }
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        do {
            // Using .deviceOwnerAuthentication allows automatic fallback to device passcode
            // if Face ID / Touch ID fails or is locked out.
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                self.lastErrorMessage = nil
                return (true, nil)
            } else {
                self.lastErrorMessage = "Authentication failed."
                return (false, nil)
            }
        } catch let laError as LAError {
            let userFriendlyMessage = resolveErrorMessage(for: laError)
            self.lastErrorMessage = userFriendlyMessage
            return (false, laError)
        } catch {
            self.lastErrorMessage = error.localizedDescription
            return (false, nil)
        }
    }
    
    // MARK: - Error Handling
    
    private func resolveErrorMessage(for error: LAError) -> String? {
        switch error.code {
        case .userCancel:
            return "Unlock cancelled."
        case .userFallback:
            return "Passcode requested."
        case .biometryLockout:
            return "Too many failed attempts. Please unlock with your device passcode."
        case .biometryNotAvailable:
            return "Biometrics are unavailable. Please use your device passcode."
        case .biometryNotEnrolled:
            return "No biometrics enrolled. Please set up Face ID or Passcode in iOS Settings."
        case .authenticationFailed:
            return "Identity could not be verified. Please try again."
        case .systemCancel, .appCancel:
            return nil
        default:
            return error.localizedDescription
        }
    }
}
