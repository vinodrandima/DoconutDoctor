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
        
        // Check if user previously opted to continue offline
        let prefersOffline = UserDefaults.standard.bool(forKey: offlinePreferenceUserKey)
        
        if isFirebaseConfigured {
            setupAuthListener(prefersOffline: prefersOffline)
        } else {
            // Firebase not configured in bundle -> Default to offline
            self.authState = .offline
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
            self.errorMessage = error.localizedDescription
            throw error
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
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    public func signOut() throws {
        if isFirebaseConfigured {
            try Auth.auth().signOut()
        }
        self.currentUID = nil
        self.currentUserEmail = nil
        self.authState = .signedOut
        UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
    }
    
    public func continueOffline() {
        self.authState = .offline
        UserDefaults.standard.set(true, forKey: offlinePreferenceUserKey)
        self.errorMessage = nil
    }
    
    public func switchAccount() {
        self.authState = .signedOut
        UserDefaults.standard.set(false, forKey: offlinePreferenceUserKey)
    }
}

public enum AuthError: LocalizedError {
    case firebaseNotConfigured
    case unauthenticated
    
    public var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase configuration file (GoogleService-Info.plist) is missing. Cloud sync is unavailable."
        case .unauthenticated:
            return "Please sign in to sync your scan history to the cloud."
        }
    }
}
