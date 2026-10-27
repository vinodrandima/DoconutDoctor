//
//  LoginView.swift
//  CoconutDoctor
//
//  Dedicated Sign In screen with email/password authentication, password reset,
//  and offline guest mode.
//

import SwiftUI

public struct LoginView: View {
    @ObservedObject var authService: AuthService
    public var onSwitchToRegister: (() -> Void)? = nil
    public var onDismiss: (() -> Void)? = nil
    
    private enum Field: Hashable {
        case email
        case password
    }
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var localError: String? = nil
    @State private var showForgotPasswordAlert: Bool = false
    @State private var resetEmailSentAlert: Bool = false
    @FocusState private var focusedField: Field?
    
    public init(
        authService: AuthService,
        onSwitchToRegister: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.authService = authService
        self.onSwitchToRegister = onSwitchToRegister
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header & Branding
                    headerSection
                    
                    // MARK: - Credentials Card
                    credentialsCard
                    
                    // MARK: - Offline Guest Bypass
                    offlineBypassSection
                    
                    // MARK: - Switch to Register Footer
                    if let onSwitch = onSwitchToRegister {
                        switchFooterSection(onSwitch)
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .onTapGesture {
                focusedField = nil
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onDismiss = onDismiss {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guest Mode") {
                        focusedField = nil
                        authService.continueOffline()
                        onDismiss?()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appAccent)
                }
            }
            .onChange(of: email) { _, _ in
                clearErrors()
            }
            .onChange(of: password) { _, _ in
                clearErrors()
            }
            .alert("Reset Password", isPresented: $showForgotPasswordAlert) {
                TextField("Email address", text: $email)
                    .autocapitalization(.none)
                Button("Send Reset Link") {
                    handlePasswordReset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email address to receive a password reset link.")
            }
            .alert("Email Sent", isPresented: $resetEmailSentAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("A password reset link has been sent to \(email). Check your inbox.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .padding(.top, 8)
            
            VStack(spacing: 4) {
                Text("Welcome Back")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Sign in to sync leaf diagnoses, farm map pins, and plantation telemetry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
        }
    }
    
    // MARK: - Credentials Card
    
    private var credentialsCard: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.subheadline)
                        .foregroundStyle(focusedField == .email ? Color.appAccent : .secondary)
                        .frame(width: 20)
                    
                    TextField("farmer@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                .padding(14)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.appAccent : Color.clear, lineWidth: 1.5)
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Password")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Forgot?") {
                        focusedField = nil
                        showForgotPasswordAlert = true
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.appAccent)
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(focusedField == .password ? Color.appAccent : .secondary)
                        .frame(width: 20)
                    
                    if isPasswordVisible {
                        TextField("••••••••", text: $password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                handleSignIn()
                            }
                    } else {
                        SecureField("••••••••", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                handleSignIn()
                            }
                    }
                    
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.appAccent : Color.clear, lineWidth: 1.5)
                )
            }
            
            // Error Message Banner
            if let error = localError ?? authService.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            
            // Sign In Button
            Button {
                handleSignIn()
            } label: {
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.headline)
                        Text("Sign In")
                            .font(.headline.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(authService.isLoading)
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Offline Bypass Section
    
    private var offlineBypassSection: some View {
        VStack(spacing: 14) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.25))
                Text("OR")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.25))
            }
            
            Button {
                focusedField = nil
                authService.continueOffline()
                onDismiss?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.subheadline)
                    Text("Continue as Guest Farmer (Offline Mode)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
                )
            }
            .accessibilityLabel("Continue as Guest Farmer without signing in.")
        }
    }
    
    // MARK: - Switch to Register Footer
    
    private func switchFooterSection(_ onSwitch: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                focusedField = nil
                onSwitch()
            } label: {
                Text("Register")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Logic
    
    private func clearErrors() {
        if localError != nil { localError = nil }
        if authService.errorMessage != nil { authService.errorMessage = nil }
    }
    
    private func handleSignIn() {
        focusedField = nil
        clearErrors()
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            localError = "Please enter your email address."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            focusedField = .email
            return
        }
        
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            localError = "Please enter a valid email address (e.g. farmer@example.com)."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            focusedField = .email
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            localError = "Please enter your password."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            focusedField = .password
            return
        }
        
        Task {
            do {
                try await authService.signIn(email: trimmedEmail, password: trimmedPassword)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss?()
            } catch {
                localError = AuthService.friendlyErrorMessage(from: error)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
    
    private func handlePasswordReset() {
        focusedField = nil
        clearErrors()
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty && trimmedEmail.contains("@") else {
            localError = "Please enter a valid email address to receive the reset link."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        
        Task {
            do {
                try await authService.sendPasswordReset(email: trimmedEmail)
                resetEmailSentAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                localError = AuthService.friendlyErrorMessage(from: error)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    LoginView(authService: AuthService())
        .withDependencies(.preview)
}
