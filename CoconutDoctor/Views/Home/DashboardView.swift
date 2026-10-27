//
//  DashboardView.swift
//  CoconutDoctor
//
//  Home Dashboard view providing plantation health overview, quick actions,
//  summary telemetry, mini-charts, and outbreak warnings.
//

import SwiftUI
import Charts

public struct DashboardView: View {
    @ObservedObject var tabSelection: TabSelectionModel
    @StateObject private var viewModel: DashboardViewModel
    @Environment(\.dependencies) private var dependencies
    
    @State private var isAlertDismissed: Bool = false
    @State private var selectedScanForDetail: ScanRecord? = nil
    @State private var showNotificationsSheet: Bool = false
    
    public init(
        tabSelection: TabSelectionModel,
        viewModel: DashboardViewModel? = nil
    ) {
        self.tabSelection = tabSelection
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: DashboardViewModel())
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 20) {
                        // MARK: - Section A: Farmer Greeting & Cloud Status Header
                        headerSection
                        
                        // MARK: - Section F: Disease Outbreak Alert Banner
                        if let alert = viewModel.diseaseAlert, !isAlertDismissed {
                            diseaseAlertBanner(alert)
                        }
                        
                        // MARK: - Section B: Quick Actions
                        quickActionsSection
                        
                        if viewModel.statsViewModel.totalScans == 0 && !viewModel.isLoading {
                            // MARK: - Empty State (0 Scans)
                            emptyStateCard
                        } else {
                            // MARK: - Section C: 2x2 Farm Summary Cards Grid
                            summaryCardsGrid
                            
                            // MARK: - Section D: Recent Scans (Latest 3)
                            recentScansSection
                            
                            // MARK: - Section E: Mini 8-Week Trend Chart
                            miniChartSection
                                .id("miniChart")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .onAppear {
                        if ProcessInfo.processInfo.arguments.contains("-bottom") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    proxy.scrollTo("miniChart", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("CoconutDoctor")
                            .font(.headline.weight(.bold))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNotificationsSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                            
                            if viewModel.diseaseAlert != nil {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 9, height: 9)
                                    .overlay(
                                        Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 1.5)
                                    )
                                    .offset(x: 1, y: -1)
                            }
                        }
                    }
                    .accessibilityLabel("Farm Alerts and Notifications")
                }
            }
            .refreshable {
                viewModel.loadDashboard()
            }
            .onAppear {
                viewModel.loadDashboard()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScanRecordsUpdated"))) { _ in
                viewModel.loadDashboard()
            }
            .sheet(item: $selectedScanForDetail) { scan in
                NavigationStack {
                    ResultView(
                        result: scan.toClassificationResult(),
                        image: scan.imageThumbnail.flatMap(UIImage.init),
                        isFromHistory: true,
                        onScanAgain: {
                            selectedScanForDetail = nil
                            tabSelection.navigate(to: .detect)
                        }
                    )
                }
            }
            .sheet(isPresented: $showNotificationsSheet) {
                FarmAlertsSheetView(
                    diseaseAlert: viewModel.diseaseAlert,
                    onNavigateToDetect: {
                        tabSelection.navigate(to: .detect)
                    }
                )
            }
        }
    }
    
    // MARK: - A. Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text("\(viewModel.greetingText), \(viewModel.farmerName)")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Your coconut plantation health overview")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Sync status badge button
            SyncStatusBadge(
                syncManager: dependencies.syncManager,
                authService: dependencies.authService
            )
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.greetingText), \(viewModel.farmerName). Today is \(Date().formatted(date: .complete, time: .omitted)).")
    }
    
    // MARK: - F. Disease Alert Banner
    
    private func diseaseAlertBanner(_ alert: DiseaseAlert) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(alert.disease.themeColor)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        withAnimation {
                            isAlertDismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Circle().fill(Color(uiColor: .tertiarySystemFill)))
                    }
                    .accessibilityLabel("Dismiss Alert")
                }
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.85))
                
                Text(alert.recommendation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(alert.disease.themeColor.opacity(0.12))
                .stroke(alert.disease.themeColor.opacity(0.35), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alert: \(alert.title). \(alert.message)")
    }
    
    // MARK: - B. Quick Actions Row
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // New Scan Button
            Button {
                tabSelection.navigate(to: .detect)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "camera.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("New Scan")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Diagnose Leaf")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.bold())
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("New Scan. Diagnose coconut leaf.")
            
            // Farm Map Button
            Button {
                tabSelection.navigate(to: .map)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "map.fill")
                            .font(.title3.bold())
                            .foregroundStyle(Color.teal)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Farm Map")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("View GPS Pins")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
                )
            }
            .accessibilityLabel("Farm Map. View diagnosed trees on GPS map.")
        }
    }
    
    // MARK: - C. Summary Cards Grid (2x2)
    
    private var summaryCardsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            // Card 1: Total Scans
            metricCard(
                title: "Total Scans",
                value: "\(viewModel.statsViewModel.totalScans)",
                icon: "leaf.fill",
                iconColor: Color.appAccent,
                footnote: "All time diagnoses"
            )
            .accessibilityLabel("Total Scans: \(viewModel.statsViewModel.totalScans)")
            
            // Card 2: Most Common Disease
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill((viewModel.statsViewModel.mostCommonDisease?.themeColor ?? Color.secondary).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Circle()
                            .fill(viewModel.statsViewModel.mostCommonDisease?.themeColor ?? Color.secondary)
                            .frame(width: 14, height: 14)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.statsViewModel.mostCommonDisease?.displayName ?? "None yet")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("Top Diagnosis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("Most Common Diagnosis: \(viewModel.statsViewModel.mostCommonDisease?.displayName ?? "None yet")")
            
            // Card 3: Farm Health Ratio
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color.appHealthy.opacity(0.2), lineWidth: 3.5)
                            .frame(width: 32, height: 32)
                        Circle()
                            .trim(from: 0, to: viewModel.healthRatio)
                            .stroke(Color.appHealthy, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appHealthy)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.healthRatioFormatted)
                        .font(.title3.bold())
                        .foregroundStyle(Color.appHealthy)
                    Text("Farm Health Ratio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("Farm Health Ratio: \(viewModel.healthRatioFormatted)")
            
            // Card 4: Scans This Week
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }
                    Spacer()
                    
                    // Tiny trend badge
                    trendBadge
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.scansThisWeekCount)")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Scans This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("Scans This Week: \(viewModel.scansThisWeekCount)")
        }
    }
    
    private var trendBadge: some View {
        HStack(spacing: 2) {
            if viewModel.weeklyTrendDelta > 0 {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.green)
                Text("+\(viewModel.weeklyTrendDelta)")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.green)
            } else if viewModel.weeklyTrendDelta < 0 {
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                Text("\(viewModel.weeklyTrendDelta)")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.secondary)
            } else {
                Text("—")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(Capsule())
    }
    
    private func metricCard(title: String, value: String, icon: String, iconColor: Color, footnote: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - D. Recent Scans Section
    
    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Diagnoses")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    tabSelection.navigate(to: .history)
                } label: {
                    HStack(spacing: 3) {
                        Text("See All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.appAccent)
                }
                .accessibilityLabel("See all scan history")
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentScans) { scan in
                        Button {
                            selectedScanForDetail = scan
                        } label: {
                            recentScanCard(scan)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func recentScanCard(_ scan: ScanRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail or icon placeholder
            ZStack(alignment: .topTrailing) {
                if let data = scan.imageThumbnail, let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 95)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scan.disease.themeColor.opacity(0.12))
                        .frame(width: 140, height: 95)
                        .overlay(
                            Image(systemName: scan.disease.iconName)
                                .font(.title)
                                .foregroundStyle(scan.disease.themeColor)
                        )
                }
                
                // Confidence badge
                Text(String(format: "%.0f%%", scan.confidence * 100))
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(6)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(scan.disease.themeColor)
                        .frame(width: 7, height: 7)
                    Text(scan.disease.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Text(scan.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, alignment: .leading)
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scan.disease.displayName) diagnosed on \(scan.timestamp.formatted(date: .abbreviated, time: .shortened)). Confidence \(Int(scan.confidence * 100)) percent.")
    }
    
    // MARK: - E. Mini Chart Section
    
    private var miniChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("8-Week Scan Velocity")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                    Text("Weekly diagnosis activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    tabSelection.navigate(to: .stats)
                } label: {
                    HStack(spacing: 3) {
                        Text("See full stats")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.appAccent)
                }
                .accessibilityLabel("See full statistics tab")
            }
            
            if !viewModel.statsViewModel.scansPerWeek.isEmpty {
                Chart(viewModel.statsViewModel.scansPerWeek) { item in
                    BarMark(
                        x: .value("Week", item.weekStart, unit: .weekOfYear),
                        y: .value("Scans", item.count)
                    )
                    .foregroundStyle(Color.appAccent.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .padding(.top, 4)
            }
            
            // Disease breakdown chip row
            HStack(spacing: 6) {
                ForEach(viewModel.statsViewModel.perDiseaseCounts) { item in
                    if item.count > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.disease.themeColor)
                                .frame(width: 6, height: 6)
                            Text("\(item.disease.displayName): \(item.count)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.disease.themeColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State (0 Scans)
    
    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text("Welcome to CoconutDoctor")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Text("Scan your first coconut leaf to see your farm dashboard, real-time health ratios, disease tracking, and GPS mapping.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Button {
                tabSelection.navigate(to: .detect)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Scan First Coconut Leaf")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.appAccent)
                .clipShape(Capsule())
                .shadow(color: Color.appAccent.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to CoconutDoctor. Scan your first coconut leaf to see your farm dashboard.")
    }
}

#Preview {
    DashboardView(tabSelection: TabSelectionModel())
        .withDependencies(.preview)
}
