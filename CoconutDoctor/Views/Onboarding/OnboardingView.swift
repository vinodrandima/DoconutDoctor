//
//  OnboardingView.swift
//  CoconutDoctor
//
//  Two-screen interactive onboarding introducing farmers to AI Disease Diagnosis
//  and Farm GPS Telemetry before transitioning to Login / Registration.
//

import SwiftUI

public struct OnboardingView: View {
    public let onComplete: () -> Void
    
    @State private var currentPage: Int = ProcessInfo.processInfo.arguments.contains("-onboarding-page2") ? 1 : 0
    @Environment(\.dependencies) private var dependencies
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background subtle gradient
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top bar with branding & Skip button
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Paged content (Screen 1 & Screen 2)
                    TabView(selection: $currentPage) {
                        onboardingPageOne
                            .tag(0)
                        
                        onboardingPageTwo
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                    
                    // Bottom Navigation: Indicator + Buttons
                    bottomControls
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("CoconutDoctor")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            if currentPage < 1 {
                Button("Skip") {
                    withAnimation {
                        currentPage = 1
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Skip to second onboarding screen")
            } else {
                Button("Skip to Sign In") {
                    onComplete()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appAccent)
                .accessibilityLabel("Skip onboarding and go to Sign In")
            }
        }
    }
    
    // MARK: - Screen 1: Instant AI Leaf Diagnosis
    
    private var onboardingPageOne: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 10)
            
            // Hero Illustration
            ZStack {
                // Outer glow pulse rings
                Circle()
                    .fill(Color.appAccent.opacity(0.08))
                    .frame(width: 250, height: 250)
                Circle()
                    .fill(Color.appAccent.opacity(0.14))
                    .frame(width: 190, height: 190)
                
                // Card Mockup
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .frame(width: 170, height: 170)
                    .shadow(color: Color.appAccent.opacity(0.2), radius: 16, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1.5)
                    )
                
                // Scanning brackets & palm leaf
                VStack(spacing: 8) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 68, weight: .light))
                        .foregroundStyle(Color.appAccent)
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(Color.appHealthy)
                        )
                    
                    // Laser scan indicator bar
                    Capsule()
                        .fill(Color.appAccent)
                        .frame(width: 60, height: 3)
                        .shadow(color: Color.appAccent, radius: 4)
                }
                
                // Floating diagnostic chip: Top Right
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.appHealthy)
                        .frame(width: 6, height: 6)
                    Text("Healthy Palm: 99%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.appHealthy)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                .offset(x: 70, y: -75)
                
                // Floating diagnostic chip: Bottom Left
                HStack(spacing: 4) {
                    Circle()
                        .fill(DiseaseType.budRot.themeColor)
                        .frame(width: 6, height: 6)
                    Text("Bud Rot: 96%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DiseaseType.budRot.themeColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                .offset(x: -65, y: 75)
            }
            .frame(height: 260)
            
            // Text Content
            VStack(spacing: 12) {
                // Category Tag
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("AI-POWERED PALM CARE")
                        .font(.caption2.bold())
                }
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.appAccent.opacity(0.12))
                .clipShape(Capsule())
                
                Text("Instant Leaf Disease Diagnosis")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Text("Point your iPhone camera at coconut fronds to instantly detect Bud Rot, Leaf Rot, or verify healthy trees with millisecond on-device AI.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(2)
            }
            
            // Features Row
            VStack(alignment: .leading, spacing: 10) {
                featureBullet(
                    icon: "bolt.fill",
                    color: .orange,
                    title: "100% Offline Core ML",
                    subtitle: "Zero latency, runs without cellular network in remote groves."
                )
                featureBullet(
                    icon: "cross.case.fill",
                    color: Color.appAccent,
                    title: "CRI Treatment Guides",
                    subtitle: "Coconut Research Institute agronomy action steps."
                )
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            
            Spacer(minLength: 10)
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Screen 1 of 2: Instant Leaf Disease Diagnosis with offline AI and CRI treatment guides.")
    }
    
    // MARK: - Screen 2: Farm Telemetry & Cloud Sync
    
    private var onboardingPageTwo: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 10)
            
            // Hero Illustration
            ZStack {
                // Outer glow pulse rings
                Circle()
                    .fill(Color.teal.opacity(0.08))
                    .frame(width: 250, height: 250)
                Circle()
                    .fill(Color.teal.opacity(0.14))
                    .frame(width: 190, height: 190)
                
                // Card Mockup
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .frame(width: 170, height: 170)
                    .shadow(color: Color.teal.opacity(0.2), radius: 16, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.teal.opacity(0.3), lineWidth: 1.5)
                    )
                
                // Map pins illustration
                VStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(Color.teal)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(DiseaseType.budRot.themeColor)
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.appHealthy)
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(DiseaseType.leafRot.themeColor)
                    }
                    .font(.caption)
                }
                
                // Floating diagnostic chip: Top Left
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text("Auto GPS Tagging")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                .offset(x: -60, y: -75)
                
                // Floating diagnostic chip: Bottom Right
                HStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 9))
                    Text("Cloud Sync Active")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                .offset(x: 65, y: 75)
            }
            .frame(height: 260)
            
            // Text Content
            VStack(spacing: 12) {
                // Category Tag
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                    Text("SMART FARM MANAGEMENT")
                        .font(.caption2.bold())
                }
                .foregroundStyle(Color.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.teal.opacity(0.12))
                .clipShape(Capsule())
                
                Text("Track Outbreaks & Farm Map")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Text("Pin infected palms to your farm map, receive early outbreak warnings, and backup your plantation history securely.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(2)
            }
            
            // Features Row
            VStack(alignment: .leading, spacing: 10) {
                featureBullet(
                    icon: "exclamationmark.triangle.fill",
                    color: DiseaseType.budRot.themeColor,
                    title: "Early Outbreak Warnings",
                    subtitle: "Automated alert when a disease spreads across your block."
                )
                featureBullet(
                    icon: "cloud.fill",
                    color: .blue,
                    title: "Firebase Cloud Sync",
                    subtitle: "Restore records on new devices or work offline anytime."
                )
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            
            Spacer(minLength: 10)
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Screen 2 of 2: Track Outbreaks and Farm Map with GPS tagging and cloud sync.")
    }
    
    private func featureBullet(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.footnote.bold())
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page Indicator Dots
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.appAccent : Color.secondary.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.vertical, 4)
            
            // Primary Action Button
            Button {
                if currentPage < 1 {
                    withAnimation {
                        currentPage = 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < 1 ? "Continue" : "Get Started")
                        .font(.headline.weight(.bold))
                    Image(systemName: currentPage < 1 ? "arrow.right" : "arrow.right.circle.fill")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.appAccent.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .accessibilityLabel(currentPage < 1 ? "Continue to next screen" : "Get Started and continue to Login")
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .withDependencies(.preview)
}
