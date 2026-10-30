//
//  StatsView.swift
//  CoconutDoctor
//
//  Disease trends & health statistics dashboard using Swift Charts.
//

import SwiftUI
import Charts

public struct StatsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel: StatsViewModel
    @State private var chartDisplayMode: ChartDisplayMode = .donut
    
    private enum ChartDisplayMode: String, CaseIterable, Identifiable {
        case donut = "Donut"
        case bar = "Bar"
        var id: String { rawValue }
    }
    
    public init(viewModel: StatsViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: StatsViewModel())
        }
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.totalScans == 0 {
                    ProgressView("Calculating plantation statistics...")
                } else if viewModel.totalScans == 0 {
                    emptyStateView
                } else {
                    dashboardScrollView
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchStatistics()
            }
            .refreshable {
                viewModel.fetchStatistics()
            }
        }
    }
    
    // MARK: - Dashboard Content
    
    private var dashboardScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Top Summary Metric Cards
                summaryCardsGrid
                
                // 2. Scans Per Disease (Donut / Bar Chart)
                diseaseDistributionCard
                
                // 3. Scans Over Time Line Chart (Last 8 Weeks)
                weeklyTrendCard
                
                // 4. Farm Health Overview Bar (Healthy vs Diseased)
                healthRatioCard
                
                // 5. Model Accuracy / Confidence Per Disease
                confidenceBreakdownCard
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 860 : .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Summary Cards
    
    private var summaryCardsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Total Scans",
                value: "\(viewModel.totalScans)",
                icon: "doc.text.image",
                color: Color.appAccent
            )
            
            metricCard(
                title: "Most Common",
                value: viewModel.mostCommonDisease?.displayName ?? "None",
                icon: viewModel.mostCommonDisease?.iconName ?? "leaf",
                color: viewModel.mostCommonDisease?.themeColor ?? .secondary
            )
            
            metricCard(
                title: "Avg Confidence",
                value: String(format: "%.0f%%", viewModel.overallAverageConfidence * 100),
                icon: "checkmark.seal.fill",
                color: .blue
            )
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.8)
        )
    }
    
    // MARK: - Farm Health Ratio Card
    
    private var healthRatioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Plantation Health Ratio")
                    .font(.headline)
                Spacer()
                let healthyPercent = viewModel.totalScans > 0 ? (Double(viewModel.healthyCount) / Double(viewModel.totalScans)) * 100.0 : 0.0
                Text(String(format: "%.0f%% Healthy", healthyPercent))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.diseaseHealthy)
            }
            
            // Stacked Health Bar
            GeometryReader { geo in
                HStack(spacing: 3) {
                    let healthyWidth = viewModel.totalScans > 0 ? geo.size.width * CGFloat(Double(viewModel.healthyCount) / Double(viewModel.totalScans)) : 0
                    let diseasedWidth = geo.size.width - healthyWidth
                    
                    if healthyWidth > 0 {
                        Capsule()
                            .fill(Color.diseaseHealthy)
                            .frame(width: max(8, healthyWidth), height: 12)
                    }
                    if diseasedWidth > 0 {
                        Capsule()
                            .fill(Color.diseaseBudRot)
                            .frame(width: max(8, diseasedWidth), height: 12)
                    }
                }
            }
            .frame(height: 12)
            
            HStack {
                Label("\(viewModel.healthyCount) Healthy Palms", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.diseaseHealthy)
                Spacer()
                Label("\(viewModel.diseasedCount) Diseased Palms", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.diseaseBudRot)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Disease Distribution Chart
    
    private var diseaseDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Disease Distribution")
                        .font(.headline)
                    Text("Breakdown of identified symptoms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Donut vs Bar Picker
                Picker("Mode", selection: $chartDisplayMode) {
                    ForEach(ChartDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
            }
            
            let activeItems = viewModel.perDiseaseCounts.filter { $0.count > 0 }
            
            if chartDisplayMode == .donut {
                // Swift Charts Donut
                Chart(activeItems) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.62),
                        angularInset: 2.5
                    )
                    .cornerRadius(6)
                    .foregroundStyle(item.disease.themeColor)
                }
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("\(viewModel.totalScans)")
                            .font(.system(.title2, design: .rounded).bold())
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 200)
            } else {
                // Swift Charts Horizontal Bar
                Chart(activeItems) { item in
                    BarMark(
                        x: .value("Scans", item.count),
                        y: .value("Disease", item.disease.displayName)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.disease.themeColor)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .frame(height: max(140, CGFloat(activeItems.count * 36)))
            }
            
            // Legend table
            VStack(spacing: 8) {
                ForEach(viewModel.perDiseaseCounts) { item in
                    HStack {
                        Circle()
                            .fill(item.disease.themeColor)
                            .frame(width: 10, height: 10)
                        
                        Text(item.disease.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.count) scans")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(.caption.bold())
                            .foregroundStyle(item.count > 0 ? item.disease.themeColor : .secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    if item.id != viewModel.perDiseaseCounts.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Scans Over Time Line Chart
    
    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Diagnostic Trend (Last 8 Weeks)")
                    .font(.headline)
                Text("Scan volume over time across your farm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart(viewModel.scansPerWeek) { item in
                AreaMark(
                    x: .value("Week", item.weekStart, unit: .weekOfYear),
                    y: .value("Scans", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.35), Color.appAccent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Week", item.weekStart, unit: .weekOfYear),
                    y: .value("Scans", item.count)
                )
                .foregroundStyle(Color.appAccent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Week", item.weekStart, unit: .weekOfYear),
                    y: .value("Scans", item.count)
                )
                .foregroundStyle(Color.appAccent)
                .symbolSize(36)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Confidence Breakdown Card
    
    private var confidenceBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Average Model Confidence")
                    .font(.headline)
                Text("On-device inference certainty per symptom")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.avgConfidencePerDisease) { item in
                    VStack(spacing: 5) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: item.disease.iconName)
                                    .font(.caption)
                                    .foregroundStyle(item.disease.themeColor)
                                Text(item.disease.displayName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.1f%% avg", item.averageConfidence * 100))
                                .font(.subheadline.bold())
                                .foregroundStyle(item.disease.themeColor)
                        }
                        
                        // Styled progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 7)
                                
                                Capsule()
                                    .fill(item.disease.themeColor)
                                    .frame(
                                        width: max(7, geo.size.width * CGFloat(min(max(item.averageConfidence, 0), 1))),
                                        height: 7
                                    )
                            }
                        }
                        .frame(height: 7)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Diagnostic Data Yet", systemImage: "chart.bar.xaxis")
                .foregroundStyle(Color.appAccent)
        } description: {
            Text("Perform leaf diagnoses in the Detect tab. Visual disease distribution charts, plantation health metrics, and weekly scan trends will appear here automatically.")
                .padding(.horizontal, 24)
        }
    }
}

#Preview("StatsView - Populated") {
    let mockScans = [
        ScanRecord(disease: .budRot, confidence: 0.94, date: Date()),
        ScanRecord(disease: .budRot, confidence: 0.92, date: Date().addingTimeInterval(-86400 * 3)),
        ScanRecord(disease: .greyLeafSpot, confidence: 0.88, date: Date().addingTimeInterval(-86400 * 10)),
        ScanRecord(disease: .healthy, confidence: 0.98, date: Date().addingTimeInterval(-86400 * 15)),
        ScanRecord(disease: .healthy, confidence: 0.99, date: Date().addingTimeInterval(-86400 * 20)),
        ScanRecord(disease: .leafRot, confidence: 0.85, date: Date().addingTimeInterval(-86400 * 28))
    ]
    let repo = ScanRepository(initialRecords: mockScans)
    let vm = StatsViewModel(scanRepository: repo)
    StatsView(viewModel: vm)
}

#Preview("StatsView - Empty") {
    let emptyRepo = ScanRepository(initialRecords: [])
    let vm = StatsViewModel(scanRepository: emptyRepo)
    StatsView(viewModel: vm)
}
