//
//  LoginView.swift
//  CoconutDoctor
//
//  Authentication view supporting Email/Password Sign In & Registration via FirebaseAuth,
//  plus a "Continue Offline" guest workflow.
//

import SwiftUI

public struct LoginView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = false
    @State private var localError: String? = nil
    
    public init(authService: AuthService) {
        self.authService = authService
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header & Branding
                    headerSection
                    
                    // MARK: - Offline / Missing Config Notice (if applicable)
                    if !authService.isFirebaseConfigured {
                        offlineConfigBanner
                    }
                    
                    // MARK: - Credentials Card
                    credentialsCard
                    
                    // MARK: - Offline Bypass Button
                    offlineBypassSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(isSignUpMode ? "Create Account" : "Welcome Back")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        authService.continueOffline()
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.top, 12)
            
            Text("CoconutDoctor Cloud")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text("Backup diagnosis records, view farm telemetry, and sync across your devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
    
    private var offlineConfigBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("Offline Mode Active")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            Text("Firebase configuration (GoogleService-Info.plist) is not currently bundled. All camera detection, treatment advice, and Core Data history remain 100% functional offline.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.08))
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var credentialsCard: some View {
        VStack(spacing: 16) {
            // Mode Switcher
            Picker("Mode", selection: $isSignUpMode) {
                Text("Sign In").tag(false)
                Text("Create Account").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(!authService.isFirebaseConfigured)
            
            VStack(alignment: .leading, spacing: 14) {
                // Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email Address")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.secondary)
                        TextField("farmer@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                        SecureField("••••••••", text: $password)
                            .textContentType(isSignUpMode ? .newPassword : .password)
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                
                // Confirm Password (Sign Up only)
                if isSignUpMode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.secondary)
                            SecureField("••••••••", text: $confirmPassword)
                                .textContentType(.newPassword)
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
            }
            .disabled(!authService.isFirebaseConfigured)
            
            // Error Display
            if let errorMsg = localError ?? authService.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMsg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            
            // Submit Button
            Button {
                handleSubmit()
            } label: {
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isSignUpMode ? "person.badge.plus" : "arrow.right.circle.fill")
                        Text(isSignUpMode ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(authService.isFirebaseConfigured ? Color.appAccent : Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!authService.isFirebaseConfigured || authService.isLoading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
    
    private var offlineBypassSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.2))
                Text("OR")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.2))
            }
            .padding(.vertical, 4)
            
            Button {
                authService.continueOffline()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.gen3")
                    Text("Continue Offline (Guest)")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .background(Color(uiColor: .secondarySystemGroupedBackground).cornerRadius(12))
                )
                .foregroundStyle(.primary)
            }
            
            Text("Core Data retains all diagnosis records on-device. You can link a cloud account at any time.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        localError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            localError = "Please enter an email address."
            return
        }
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters."
            return
        }
        if isSignUpMode && password != confirmPassword {
            localError = "Passwords do not match."
            return
        }
        
        Task {
            do {
                if isSignUpMode {
                    try await authService.signUp(email: trimmedEmail, password: password)
                } else {
                    try await authService.signIn(email: trimmedEmail, password: password)
                }
                dismiss()
            } catch {
                // authService.errorMessage is updated
            }
        }
    }
}

#Preview {
    LoginView(authService: AuthService())
}
