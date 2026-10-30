//
//  TreatmentView.swift
//  CoconutDoctor
//
//  Trilingual farmer-friendly treatment advice and prevention care screen.
//

import SwiftUI

public struct TreatmentView: View {
    public let disease: DiseaseType
    
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var selectedLanguage: AppLanguage = .currentDeviceLanguage
    
    public init(disease: DiseaseType, initialLanguage: AppLanguage? = nil) {
        self.disease = disease
        if let lang = initialLanguage {
            _selectedLanguage = State(initialValue: lang)
        }
    }
    
    private var treatment: TreatmentInfo {
        dependencies.treatmentService.getTreatment(for: disease, language: selectedLanguage)
    }
    
    private var isHealthy: Bool {
        disease == .healthy
    }
    
    private var primaryColor: Color {
        isHealthy ? .diseaseHealthy : disease.themeColor
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Language Selector
                languageSelectorCard
                
                // MARK: - Header Hero Card
                heroHeaderCard
                
                // MARK: - Official Consultation Callout
                consultationBanner
                
                // MARK: - Disease Description Card
                contentCard(
                    title: isHealthy ? localizedSectionTitle("Palm Health Overview", "ගසේ සෞඛ්‍යය දළ විශ්ලේෂණය", "தென்னை நலம் பற்றிய விபரம்") :
                                       localizedSectionTitle("About Disease", "රෝගය පිළිබඳ හැඳින්වීම", "நோய் பற்றிய விபரம்"),
                    icon: "info.circle.fill",
                    accentColor: .blue
                ) {
                    Text(treatment.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
                
                // MARK: - Chemical / Recommended Interventions
                contentCard(
                    title: isHealthy ? localizedSectionTitle("Recommended Fertilizers", "නිර්දේශිත පොහොර භාවිතය", "பரிந்துரைக்கப்பட்ட உரங்கள்") :
                                       localizedSectionTitle("Chemical Treatment", "රසායනික ප්‍රතිකාර", "இரசாயன சிகிச்சை"),
                    icon: isHealthy ? "leaf.arrow.triangle.circlepath" : "flask.fill",
                    accentColor: isHealthy ? .teal : .purple
                ) {
                    bulletPointList(items: treatment.chemicalTreatment, bulletColor: isHealthy ? .teal : .purple)
                }
                
                // MARK: - Organic & Natural Interventions
                contentCard(
                    title: isHealthy ? localizedSectionTitle("Organic Manure & Moisture Care", "කාබනික පොහොර හා තෙතමනය රැකීම", "சேதன பசளை மற்றும் நீர் சேமிப்பு") :
                                       localizedSectionTitle("Organic & Cultural Treatment", "කාබනික හා සාම්ප්‍රදායික පිළියම්", "இயற்கை மற்றும் சேதன சிகிச்சை"),
                    icon: "leaf.fill",
                    accentColor: .diseaseHealthy
                ) {
                    bulletPointList(items: treatment.organicTreatment, bulletColor: .diseaseHealthy)
                }
                
                // MARK: - Prevention & Routine Maintenance
                contentCard(
                    title: isHealthy ? localizedSectionTitle("Monthly Care & Routine", "මාසික නඩත්තුව හා ආරක්ෂාව", "மாதாந்த பராமரிப்பு வழிமுறைகள்") :
                                       localizedSectionTitle("Prevention & Plantation Care", "රෝගය බෝවීම වැළැක්වීම", "நோய் தடுப்பு மற்றும் பாதுகாப்பு"),
                    icon: "shield.checkerboard",
                    accentColor: .orange
                ) {
                    bulletPointList(items: treatment.preventionTips, bulletColor: .orange)
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 720 : .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(treatment.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Language Selector
    
    private var languageSelectorCard: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                languageLabel
                Spacer()
                languagePicker
                    .frame(maxWidth: 220)
            }
            VStack(alignment: .leading, spacing: 8) {
                languageLabel
                languagePicker
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var languageLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .foregroundStyle(.secondary)
            Text("Language / භාෂාව / மொழி:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private var languagePicker: some View {
        Picker("Language", selection: $selectedLanguage) {
            ForEach(AppLanguage.allCases) { lang in
                Text(lang.displayName).tag(lang)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Hero Header Card
    
    private var heroHeaderCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.15))
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: disease.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(treatment.title)
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.primary)
                    
                    if let scientific = treatment.scientificName {
                        Text(scientific)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(disease.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(primaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(primaryColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Consultation Alert Banner
    
    private var consultationBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(localizedSectionTitle("Important Notice for Farmers", "ගොවි මහතුන්ගේ විශේෂ අවධානයට", "விவசாயிகளுக்கான முக்கிய அறிவித்தல்"))
                    .font(.footnote.bold())
                    .foregroundStyle(.primary)
                
                Text(treatment.consultationNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Card Container
    
    private func contentCard<Content: View>(
        title: String,
        icon: String,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Divider()
            
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Bullet Point List
    
    private func bulletPointList(items: [String], bulletColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(bulletColor)
                        .clipShape(Circle())
                        .padding(.top, 2)
                    
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Section Title Localization Helper
    
    private func localizedSectionTitle(_ en: String, _ si: String, _ ta: String) -> String {
        switch selectedLanguage {
        case .english: return en
        case .sinhala: return si
        case .tamil: return ta
        }
    }
}

#Preview("Treatment - BudRot (Sinhala)") {
    NavigationStack {
        TreatmentView(disease: .budRot, initialLanguage: .sinhala)
            .withDependencies(.preview)
    }
}

#Preview("Treatment - Healthy (English)") {
    NavigationStack {
        TreatmentView(disease: .healthy, initialLanguage: .english)
            .withDependencies(.preview)
    }
}

#Preview("Treatment - LeafRot (Tamil)") {
    NavigationStack {
        TreatmentView(disease: .leafRot, initialLanguage: .tamil)
            .withDependencies(.preview)
    }
}
