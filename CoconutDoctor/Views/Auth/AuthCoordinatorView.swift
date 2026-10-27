//
//  AuthCoordinatorView.swift
//  CoconutDoctor
//
//  Coordinator view managing seamless transition between Login and Register screens.
//

import SwiftUI

public struct AuthCoordinatorView: View {
    @ObservedObject var authService: AuthService
    public var onDismiss: (() -> Void)? = nil
    
    @State private var isShowingRegister: Bool = ProcessInfo.processInfo.arguments.contains("-register")
    
    public init(authService: AuthService, onDismiss: (() -> Void)? = nil) {
        self.authService = authService
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            if isShowingRegister {
                RegisterView(
                    authService: authService,
                    onSwitchToLogin: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isShowingRegister = false
                        }
                    },
                    onDismiss: onDismiss
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                LoginView(
                    authService: authService,
                    onSwitchToRegister: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isShowingRegister = true
                        }
                    },
                    onDismiss: onDismiss
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
}

#Preview {
    AuthCoordinatorView(authService: AuthService())
        .withDependencies(.preview)
}
