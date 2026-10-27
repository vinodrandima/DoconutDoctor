//
//  AuthService.swift
//  CoconutDoctor
//
//  Authentication service managing FirebaseAuth sessions with offline/guest fallback.
//

import Foundation
import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth

public enum AuthState: Equatable, Hashable, Sendable {
    case signedOut
    case signedIn(uid: String)
    case offline
    
    public var isGuestOrOffline: Bool {
        switch self {
        case .signedOut, .offline:
            return true
        case .signedIn:
            return false
        }
    }
}

@MainActor
public final class AuthService: ObservableObject, @unchecked Sendable {
    @Published public private(set) var authState: AuthState = .signedOut
    @Published public private(set) var currentUserEmail: String? = nil
    @Published public private(set) var currentUID: String? = nil
    @Published public private(set) var isFirebaseConfigured: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var isLoading: Bool = false
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private let offlinePreferenceUserKey = "CoconutDoctor.Auth.OfflinePreference"
    
    public init() {
        self.isFirebaseConfigured = FirebaseApp.allApps?.isEmpty == false
        
        if ProcessInfo.processInfo.arguments.contains("-auth") || ProcessInfo.processInfo.arguments.contains("-login") || ProcessInfo.processInfo.arguments.contains("-register") {
            self.authState = .signedOut
            UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
            return
        }
        
        if ProcessInfo.processInfo.arguments.contains("-guest") {
            self.authState = .offline
            self.currentUID = nil
            self.currentUserEmail = nil
            UserDefaults.standard.set(true, forKey: offlinePreferenceUserKey)
            return
        }
        
        // Check if user previously opted to continue offline
        let prefersOffline = UserDefaults.standard.bool(forKey: offlinePreferenceUserKey)
        
        if isFirebaseConfigured {
            setupAuthListener(prefersOffline: prefersOffline)
        } else if prefersOffline {
            self.authState = .offline
        } else {
            self.authState = .signedOut
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Listener
    
    private func setupAuthListener(prefersOffline: Bool) {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    self.currentUID = user.uid
                    self.currentUserEmail = user.email
                    self.authState = .signedIn(uid: user.uid)
                    UserDefaults.standard.set(false, forKey: self.offlinePreferenceUserKey)
                } else if prefersOffline {
                    self.currentUID = nil
                    self.currentUserEmail = nil
                    self.authState = .offline
                } else {
                    self.currentUID = nil
                    self.currentUserEmail = nil
                    self.authState = .signedOut
                }
            }
        }
    }
    
    // MARK: - Auth Actions
    
    public func signIn(email: String, password: String) async throws {
        guard isFirebaseConfigured else {
            throw AuthError.firebaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.currentUID = result.user.uid
            self.currentUserEmail = result.user.email
            self.authState = .signedIn(uid: result.user.uid)
            UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
        } catch {
            let friendly = AuthService.friendlyErrorMessage(from: error)
            self.errorMessage = friendly
            throw NSError(domain: "CoconutDoctor.Auth", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendly])
        }
    }
    
    public func signUp(email: String, password: String) async throws {
        guard isFirebaseConfigured else {
            throw AuthError.firebaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.currentUID = result.user.uid
            self.currentUserEmail = result.user.email
            self.authState = .signedIn(uid: result.user.uid)
            UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
        } catch {
            let friendly = AuthService.friendlyErrorMessage(from: error)
            self.errorMessage = friendly
            throw NSError(domain: "CoconutDoctor.Auth", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendly])
        }
    }
    
    public func signOut() {
        if isFirebaseConfigured {
            do {
                try Auth.auth().signOut()
            } catch {
                print("[AuthService] Firebase signOut notice: \(error.localizedDescription)")
            }
        }
        self.currentUID = nil
        self.currentUserEmail = nil
        self.authState = .signedOut
        UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
        self.errorMessage = nil
    }
    
    public func sendPasswordReset(email: String) async throws {
        guard isFirebaseConfigured else {
            throw AuthError.firebaseNotConfigured
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            let friendly = AuthService.friendlyErrorMessage(from: error)
            self.errorMessage = friendly
            throw NSError(domain: "CoconutDoctor.Auth", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendly])
        }
    }
    
    public func continueOffline() {
        self.authState = .offline
        UserDefaults.standard.set(true, forKey: offlinePreferenceUserKey)
        self.errorMessage = nil
    }
    
    public func switchAccount() {
        self.authState = .signedOut
        UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
        self.errorMessage = nil
    }
    
    // MARK: - Friendly Error Messages
    
    public static func friendlyErrorMessage(from error: Error) -> String {
        if let authErr = error as? AuthError {
            return authErr.localizedDescription
        }
        
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain {
            if let code = AuthErrorCode(rawValue: nsError.code) {
                switch code {
                case .invalidEmail:
                    return "Please enter a valid email address (e.g. farmer@example.com)."
                case .wrongPassword:
                    return "Incorrect password. Please verify your password or tap 'Forgot?' to reset it."
                case .userNotFound:
                    return "No account exists with this email address. Please check your spelling or tap 'Register'."
                case .userDisabled:
                    return "This account has been disabled. Please contact CoconutDoctor support."
                case .emailAlreadyInUse:
                    return "An account with this email address already exists. Please Sign In instead."
                case .weakPassword:
                    return "Password is too weak. Please use at least 6 characters with letters and numbers."
                case .networkError:
                    return "Network connection issue. Please check your internet connection or use Offline Guest Mode."
                case .invalidCredential:
                    return "Incorrect email or password. Please double check your credentials."
                case .tooManyRequests:
                    return "Too many unsuccessful attempts. For your security, please wait a moment and try again."
                case .operationNotAllowed:
                    return "Email & password sign-in is not enabled in cloud configuration."
                case .requiresRecentLogin:
                    return "Please sign in again to perform this sensitive action."
                default:
                    break
                }
            }
        }
        
        // Clean up any raw bracketed error codes
        let description = error.localizedDescription
        let cleaned = description.replacingOccurrences(of: "\\[FIRAuthErrorCode.*?\\]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "An unexpected authentication error occurred. Please try again." : cleaned
    }
}

public enum AuthError: LocalizedError {
    case firebaseNotConfigured
    case unauthenticated
    
    public var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase configuration is not active. You can continue using CoconutDoctor in Offline Guest Mode."
        case .unauthenticated:
            return "Please sign in to sync your leaf diagnosis records to the cloud."
        }
    }
}
