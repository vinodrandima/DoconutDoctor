//
//  RegisterView.swift
//  CoconutDoctor
//
//  Registration screen supporting new farmer account creation with Firebase Auth
//  or continuing in Guest / Offline mode.
//

import SwiftUI

public struct RegisterView: View {
    @ObservedObject var authService: AuthService
    public let onSwitchToLogin: () -> Void
    public var onDismiss: (() -> Void)? = nil
    
    private enum Field: Hashable {
        case fullName
        case email
        case password
        case confirmPassword
    }
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var localError: String? = nil
    @State private var showSuccessAlert: Bool = false
    @FocusState private var focusedField: Field?
    
    public init(
        authService: AuthService,
        onSwitchToLogin: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.authService = authService
        self.onSwitchToLogin = onSwitchToLogin
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header & Branding
                    headerSection
                    
                    // MARK: - Registration Form Card
                    formCard
                    
                    // MARK: - Offline Guest Bypass
                    offlineBypassSection
                    
                    // MARK: - Switch to Login Footer
                    switchFooterSection
                    
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
            .onChange(of: fullName) { _, _ in clearErrors() }
            .onChange(of: email) { _, _ in clearErrors() }
            .onChange(of: password) { _, _ in clearErrors() }
            .onChange(of: confirmPassword) { _, _ in clearErrors() }
            .alert("Account Created", isPresented: $showSuccessAlert) {
                Button("Get Started") {
                    onDismiss?()
                }
            } message: {
                Text("Welcome to CoconutDoctor! Your plantation data will now automatically sync to the cloud.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.top, 8)
            
            VStack(spacing: 4) {
                Text("Create Farm Account")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Register to sync tree diagnosis records, access satellite maps, and backup your plantation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
        }
    }
    
    // MARK: - Form Card
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: 16) {
            // Full / Farm Name Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Farmer / Plantation Name")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(focusedField == .fullName ? Color.appAccent : .secondary)
                        .frame(width: 20)
                    
                    TextField("e.g. Sunil Perera / Kurunegala Estate", text: $fullName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .email
                        }
                }
                .padding(14)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .fullName ? Color.appAccent : Color.clear, lineWidth: 1.5)
                )
            }
            
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
                    Text("Min 6 characters")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(focusedField == .password ? Color.appAccent : .secondary)
                        .frame(width: 20)
                    
                    if isPasswordVisible {
                        TextField("••••••••", text: $password)
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .confirmPassword
                            }
                    } else {
                        SecureField("••••••••", text: $password)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .confirmPassword
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
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.subheadline)
                        .foregroundStyle(focusedField == .confirmPassword ? Color.appAccent : .secondary)
                        .frame(width: 20)
                    
                    if isConfirmPasswordVisible {
                        TextField("••••••••", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.done)
                            .onSubmit {
                                handleRegister()
                            }
                    } else {
                        SecureField("••••••••", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.done)
                            .onSubmit {
                                handleRegister()
                            }
                    }
                    
                    Button {
                        isConfirmPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .confirmPassword ? Color.appAccent : Color.clear, lineWidth: 1.5)
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
            
            // Submit Button
            Button {
                handleRegister()
            } label: {
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.headline)
                        Text("Create Account")
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
            .accessibilityLabel("Continue as Guest Farmer without registering.")
        }
    }
    
    // MARK: - Switch to Login Footer
    
    private var switchFooterSection: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                focusedField = nil
                onSwitchToLogin()
            } label: {
                Text("Log In")
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
    
    private func handleRegister() {
        focusedField = nil
        clearErrors()
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            localError = "Please enter your name or plantation name."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            focusedField = .fullName
            return
        }
        
        guard !trimmedEmail.isEmpty else {
            localError = "Please enter an email address."
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
        
        guard trimmedPassword.count >= 6 else {
            localError = "Password must be at least 6 characters long."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            focusedField = .password
            return
        }
        
        guard trimmedPassword == confirmPassword else {
            localError = "Passwords do not match. Please verify both password entries."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            focusedField = .confirmPassword
            return
        }
        
        Task {
            do {
                try await authService.signUp(email: trimmedEmail, password: trimmedPassword)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showSuccessAlert = true
            } catch {
                localError = AuthService.friendlyErrorMessage(from: error)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    RegisterView(authService: AuthService(), onSwitchToLogin: {})
        .withDependencies(.preview)
}
