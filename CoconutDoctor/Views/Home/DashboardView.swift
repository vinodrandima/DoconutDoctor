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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var isAlertDismissed: Bool = false
    @State private var selectedScanForDetail: ScanRecord? = nil
    @State private var showNotificationsSheet: Bool = false
    @State private var showStatsSheet: Bool = false
    
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
                    VStack(spacing: 16) {
                        // MARK: - Section A: Farmer Greeting & Cloud Status Header
                        headerSection
                        
                        // MARK: - Hero Banner Card with Smart AI Diagnostics
                        heroBannerCard
                        
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
                    .frame(maxWidth: horizontalSizeClass == .regular ? 540 : .infinity)
                    .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
                    .padding(.top, 12)
                    .padding(.bottom, 84)
                    .frame(maxWidth: .infinity, alignment: .center)
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
            .sheet(isPresented: $showStatsSheet) {
                NavigationStack {
                    StatsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showStatsSheet = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - A. Header Section
    
    private var headerSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                headerTextContent
                Spacer()
                syncBadge
            }
            VStack(alignment: .leading, spacing: 10) {
                headerTextContent
                syncBadge
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.greetingText), \(viewModel.farmerName). Today is \(Date().formatted(date: .complete, time: .omitted)).")
    }
    
    private var headerTextContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text("\(viewModel.greetingText), \(viewModel.farmerName)")
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            
            Text("Your coconut plantation health overview")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private var syncBadge: some View {
        SyncStatusBadge(
            syncManager: dependencies.syncManager,
            authService: dependencies.authService
        )
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
    
    // MARK: - B. Quick Actions Row
    
    private var quickActionsSection: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    newScanButton
                    farmMapButton
                }
            } else {
                HStack(spacing: 12) {
                    newScanButton
                    farmMapButton
                }
            }
        }
    }
    
    private var newScanButton: some View {
        Button {
            tabSelection.navigate(to: .detect)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 38, height: 38)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Scan")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("Diagnose Leaf")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.appAccent.opacity(0.28), radius: 6, x: 0, y: 3)
        }
        .accessibilityLabel("New Scan. Diagnose coconut leaf.")
    }
    
    private var farmMapButton: some View {
        Button {
            tabSelection.navigate(to: .map)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "map.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.teal)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Farm Map")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("View GPS Pins")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
        }
        .accessibilityLabel("Farm Map. View diagnosed trees on GPS map.")
    }
    
    // MARK: - C. Summary Cards Grid
    
    private var summaryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }
    
    private var summaryCardsGrid: some View {
        LazyVGrid(
            columns: summaryColumns,
            spacing: 12
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill((viewModel.statsViewModel.mostCommonDisease?.themeColor ?? Color.secondary).opacity(0.15))
                            .frame(width: 34, height: 34)
                        Circle()
                            .fill(viewModel.statsViewModel.mostCommonDisease?.themeColor ?? Color.secondary)
                            .frame(width: 13, height: 13)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.statsViewModel.mostCommonDisease?.displayName ?? "None yet")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Top Diagnosis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("Most Common Diagnosis: \(viewModel.statsViewModel.mostCommonDisease?.displayName ?? "None yet")")
            
            // Card 3: Farm Health Ratio
            VStack(alignment: .leading, spacing: 8) {
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Farm Health")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("Farm Health: \(viewModel.healthRatioFormatted)")
            
            // Card 4: Scans This Week
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 15, weight: .bold))
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("This Week: \(viewModel.scansThisWeekCount)")
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
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(12)
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
                    showStatsSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Text("See full stats")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.appAccent)
                }
                .accessibilityLabel("See full statistics details")
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
                       // Disease breakdown chip row (horizontally scrollable so chips never clip)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Hero Banner Card with Smart AI Diagnostics
    
    private var heroBannerCard: some View {
        Button {
            tabSelection.navigate(to: .detect)
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Background Hero Image
                Image("DashboardHero")
                    .resizable()
                    .scaledToFill()
                    .frame(height: horizontalSizeClass == .regular ? 200 : 185)
                    .clipped()
                
                // Rich Gradient Overlays for readability and depth
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.35),
                        Color.clear,
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Inner Content
                VStack(alignment: .leading, spacing: 0) {
                    // Top header row: Smart AI Tag + Offline Ready Badge
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.yellow)
                            Text("AI SMART DIAGNOSIS")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Color.yellow)
                                .tracking(0.8)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Offline Ready")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                        )
                    }
                    
                    Spacer()
                    
                    // Bottom title and CTA row
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Instant Leaf Health Scanner")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                        
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("Detect Bud Rot, Leaf Rot & more in 1s")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.92))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer()
                                
                                heroScanCTA
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Detect Bud Rot, Leaf Rot & more in 1s")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.92))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                heroScanCTA
                            }
                        }
                    }
                }
                .padding(14)
            }
            .frame(height: horizontalSizeClass == .regular ? 200 : 185)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Smart Coconut Diagnosis. Instant Leaf Health Scanner. Tap to scan leaf now.")
    }
    
    private var heroScanCTA: some View {
        HStack(spacing: 4) {
            Text("Scan Leaf")
                .font(.caption.weight(.bold))
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.appAccent)
        .clipShape(Capsule())
        .shadow(color: Color.appAccent.opacity(0.4), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Empty State (0 Scans)
    
    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.top, 4)
            
            VStack(spacing: 6) {
                Text("Start Your First Plantation Diagnosis")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text("CoconutDoctor uses on-device AI to detect Bud Rot, Leaf Rot, and other conditions in seconds without internet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // 3-step quick onboarding badges
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    emptyStepItem(icon: "camera.fill", title: "Frame Leaf")
                    emptyStepItem(icon: "sparkles", title: "AI Detect")
                    emptyStepItem(icon: "cross.case.fill", title: "CRI Care")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    emptyStepItem(icon: "camera.fill", title: "1. Frame Coconut Leaf")
                    emptyStepItem(icon: "sparkles", title: "2. Instant AI Diagnosis")
                    emptyStepItem(icon: "cross.case.fill", title: "3. CRI Treatment Guide")
                }
            }
            .padding(.vertical, 4)
            
            Button {
                tabSelection.navigate(to: .detect)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Scan Coconut Leaf Now")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.appAccent)
                .clipShape(Capsule())
                .shadow(color: Color.appAccent.opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to CoconutDoctor. Tap to scan your first coconut leaf.")
    }
    
    private func emptyStepItem(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.appAccent)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(Capsule())
    }
}

#Preview {
    DashboardView(tabSelection: TabSelectionModel())
        .withDependencies(.preview)
}
