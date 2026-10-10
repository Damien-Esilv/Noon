//
//  MonitoredAppsTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import UniformTypeIdentifiers

enum MonitoredCategory: String, CaseIterable, Identifiable {
    case apps = "apps"
    case websites = "websites"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .apps: return "Applications"
        case .websites: return "Sites Web"
        }
    }
}

struct MonitoredAppsTab: View {
    @Bindable var settings: AppSettings
    
    @State private var selectedCategory: MonitoredCategory = .apps
    @State private var showFilePicker = false
    @State private var showSuggestions = false
    @State private var showWebsiteSuggestions = false
    @State private var showAddWebsiteSheet = false
    
    @State private var searchText = ""
    @State private var websiteSearchText = ""
    @State private var selectedApp: MonitoredApp?
    @State private var selectedWebsite: MonitoredWebsite?
    
    @State private var newWebsiteName = ""
    @State private var newWebsiteDomain = ""
    
    private var filteredApps: [MonitoredApp] {
        if searchText.isEmpty {
            return settings.monitoredApps
        }
        return settings.monitoredApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredWebsites: [MonitoredWebsite] {
        if websiteSearchText.isEmpty {
            return settings.monitoredWebsites
        }
        return settings.monitoredWebsites.filter {
            $0.name.localizedCaseInsensitiveContains(websiteSearchText) ||
            $0.domain.localizedCaseInsensitiveContains(websiteSearchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category segmented switcher
            categoryPicker
            
            Divider()
            
            if selectedCategory == .apps {
                appsSectionView
            } else {
                websitesSectionView
            }
        }
        .sheet(isPresented: $showSuggestions) {
            suggestionsSheet
        }
        .sheet(isPresented: $showWebsiteSuggestions) {
            websiteSuggestionsSheet
        }
        .sheet(isPresented: $showAddWebsiteSheet) {
            addWebsiteSheet
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.applicationBundle],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        HStack {
            Picker("", selection: $selectedCategory) {
                ForEach(MonitoredCategory.allCases) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .frame(minWidth: 220, maxWidth: 280)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Apps Section
    
    private var appsSectionView: some View {
        VStack(spacing: 0) {
            toolbarSection
            
            Divider()
            
            if settings.monitoredApps.isEmpty {
                emptyStateView
            } else {
                appListView
            }
            
            if !settings.invalidApps.isEmpty {
                errorBanner
            }
        }
    }
    
    // MARK: - Websites Section
    
    private var websitesSectionView: some View {
        VStack(spacing: 0) {
            websitesToolbarSection
            
            Divider()
            
            if settings.monitoredWebsites.isEmpty {
                emptyWebsitesStateView
            } else {
                websitesListView
            }
        }
    }
    
    private var websitesListView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(filteredWebsites) { site in
                    WebsiteRowView(
                        site: site,
                        isSelected: selectedWebsite?.id == site.id,
                        effectiveAccentColor: settings.effectiveAccentColor,
                        onToggle: {
                            withAnimation(.spring(response: 0.3)) {
                                settings.toggleWebsite(id: site.id)
                            }
                        },
                        onDelete: {
                            withAnimation(.spring(response: 0.3)) {
                                settings.removeWebsite(id: site.id)
                                if selectedWebsite?.id == site.id {
                                    selectedWebsite = nil
                                }
                            }
                        },
                        onSelect: {
                            selectedWebsite = site
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
    
    private var websitesToolbarSection: some View {
        HStack(spacing: 8) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 12))
                
                TextField("Rechercher un site web...", text: $websiteSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(.caption, design: .rounded))
                
                if !websiteSearchText.isEmpty {
                    Button {
                        websiteSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            Spacer()
            
            // Add from predefined suggestions
            Button {
                showWebsiteSuggestions = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .frame(width: 14)
            }
            .buttonStyle(AppleInteractiveButtonStyle(hoverScale: 1.08, pressedScale: 0.94))
            .help("Suggestions de sites web")
            
            // Add custom website
            Button {
                newWebsiteName = ""
                newWebsiteDomain = ""
                showAddWebsiteSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13))
                    .frame(width: 14)
            }
            .buttonStyle(AppleInteractiveButtonStyle(hoverScale: 1.08, pressedScale: 0.94))
            .help("Ajouter un site personnalisé")
            
            // Remove selected
            Button {
                if let site = selectedWebsite {
                    withAnimation(.spring(response: 0.3)) {
                        settings.removeWebsite(id: site.id)
                        selectedWebsite = nil
                    }
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(AppleInteractiveButtonStyle(hoverScale: 1.08, pressedScale: 0.94))
            .controlSize(.regular)
            .disabled(selectedWebsite == nil)
            .help("Supprimer le site sélectionné")
        }
        .padding(12)
    }
    
    // MARK: - Empty Websites State
    
    private var emptyWebsitesStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "globe.badge.chevron.backward")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.tertiary)
                .appleHoverEffect(scale: 1.08, liftOffset: -2, hoverTintOpacity: 0)
            
            Text("Aucun site web surveillé")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text("Ajoutez des outils web créatifs pour que Noon active automatiquement le mode créatif dans Safari, Chrome, Arc et Edge.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 12) {
                Button {
                    showWebsiteSuggestions = true
                } label: {
                    Label("Suggestions", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .appleHoverEffect(scale: 1.04, liftOffset: -1, hoverTintOpacity: 0)
                
                Button {
                    newWebsiteName = ""
                    newWebsiteDomain = ""
                    showAddWebsiteSheet = true
                } label: {
                    Label("Ajouter un site...", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .appleHoverEffect(scale: 1.04, liftOffset: -1, hoverTintOpacity: 0)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Website Suggestions Sheet
    
    private var websiteSuggestionsSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sites web suggérés")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Outils de création web populaires compatibles avec la détection automatique")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Fermer") {
                    showWebsiteSuggestions = false
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            
            Divider()
            
            // Suggestions list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(MonitoredWebsite.suggestions) { suggestion in
                        let alreadyAdded = settings.monitoredWebsites.contains {
                            $0.domain.localizedCaseInsensitiveCompare(suggestion.domain) == .orderedSame
                        }
                        
                        WebsiteSuggestionRow(
                            suggestion: suggestion,
                            alreadyAdded: alreadyAdded,
                            effectiveAccentColor: settings.effectiveAccentColor,
                            onAdd: {
                                withAnimation(.spring(response: 0.3)) {
                                    settings.addWebsite(name: suggestion.name, domain: suggestion.domain, isPredefined: true)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 440, height: 420)
    }
    
    // MARK: - Add Website Sheet
    
    private var addWebsiteSheet: some View {
        VStack(spacing: 16) {
            Text("Ajouter un site web")
                .font(.system(.headline, design: .rounded, weight: .bold))
            
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom du site")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Nom du site (ex: Spline)", text: $newWebsiteName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Domaine (ex: figma.com)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Domaine (ex: spline.design)", text: $newWebsiteDomain)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal, 4)
            
            HStack {
                Button("Annuler") {
                    showAddWebsiteSheet = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Ajouter") {
                    settings.addWebsite(name: newWebsiteName, domain: newWebsiteDomain)
                    showAddWebsiteSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newWebsiteName.trimmingCharacters(in: .whitespaces).isEmpty || newWebsiteDomain.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 320)
    }
    
    // MARK: - App Toolbar
    
    private var toolbarSection: some View {
        HStack(spacing: 8) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 12))
                
                TextField("Rechercher...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(.caption, design: .rounded))
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            Spacer()
            
            // Add from suggestions
            Button {
                showSuggestions = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .frame(width: 14)
            }
            .buttonStyle(AppleInteractiveButtonStyle(hoverScale: 1.08, pressedScale: 0.94))
            .help("Suggestions d'apps")
            
            // Add from file browser
            Button {
                showFilePicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13))
                    .frame(width: 14)
            }
            .buttonStyle(AppleInteractiveButtonStyle(hoverScale: 1.08, pressedScale: 0.94))
            .help("Ajouter depuis /Applications")
            
            // Remove selected
            Button {
                if let app = selectedApp {
                    withAnimation(.spring(response: 0.3)) {
                        settings.removeApp(app)
                        selectedApp = nil
                    }
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(AppleInteractiveButtonStyle(hoverScale: 1.08, pressedScale: 0.94))
            .controlSize(.regular)
            .disabled(selectedApp == nil)
            .help("Supprimer l'app sélectionnée")
        }
        .padding(12)
    }
    
    // MARK: - App List
    
    private var appListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredApps) { app in
                    AppRowView(
                        app: app,
                        isRunning: app.isRunning,
                        onDelete: {
                            withAnimation(.spring(response: 0.3)) {
                                settings.removeApp(app)
                                if selectedApp?.id == app.id {
                                    selectedApp = nil
                                }
                            }
                        }
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(selectedApp?.id == app.id ? Color.accentColor.opacity(0.1) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedApp = app
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.tertiary)
                .appleHoverEffect(scale: 1.08, liftOffset: -2, hoverTintOpacity: 0)
            
            Text("Aucune app surveillée")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text("Ajoutez des applications créatives pour que Noon désactive automatiquement True Tone et Night Shift.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button {
                    showSuggestions = true
                } label: {
                    Label("Suggestions", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .appleHoverEffect(scale: 1.04, liftOffset: -1, hoverTintOpacity: 0)
                
                Button {
                    showFilePicker = true
                } label: {
                    Label("Parcourir", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .appleHoverEffect(scale: 1.04, liftOffset: -1, hoverTintOpacity: 0)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error Banner
    
    private var errorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 12))
            
            Text("\(settings.invalidApps.count) app(s) introuvable(s)")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.red)
            
            Spacer()
            
            Button("Vérifier") {
                _ = settings.validateAndRepairApps()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(10)
        .background(.red.opacity(0.08))
    }
    
    // MARK: - Suggestions Sheet
    
    private var suggestionsSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Applications suggérées")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Apps créatives courantes détectées sur votre Mac")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Fermer") {
                    showSuggestions = false
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            
            Divider()
            
            // Suggestions list
            ScrollView {
                LazyVStack(spacing: 4) {
                    let sortedSuggestions = MonitoredApp.suggestions.sorted { a, b in
                        let aExists = FileManager.default.fileExists(atPath: a.path)
                        let bExists = FileManager.default.fileExists(atPath: b.path)
                        if aExists == bExists {
                            return a.name < b.name
                        }
                        return aExists && !bExists
                    }
                    
                    ForEach(sortedSuggestions) { suggestion in
                        let alreadyAdded = settings.monitoredApps.contains {
                            $0.bundleIdentifier == suggestion.bundleIdentifier
                        }
                        let exists = FileManager.default.fileExists(atPath: suggestion.path)
                        
                        HStack(spacing: 12) {
                            if let icon = suggestion.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.quaternary)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "app")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 14))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(suggestion.name)
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                
                                Text(suggestion.bundleIdentifier)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Spacer()
                            
                            if alreadyAdded {
                                Label("Ajoutée", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else if !exists {
                                Text("Non installée")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Button("Ajouter") {
                                    settings.addApp(suggestion)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .appleRowHover(cornerRadius: 8)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 440, height: 420)
    }
    
    // MARK: - File Import Handler
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier else { continue }
                
                let name = bundle.infoDictionary?[kCFBundleNameKey as String] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? url.deletingPathExtension().lastPathComponent
                
                let app = MonitoredApp(
                    name: name,
                    bundleIdentifier: bundleID,
                    path: url.path
                )
                settings.addApp(app)
            }
        case .failure(let error):
            print("File import error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Website Row View with Apple Micro-Interactions

struct WebsiteRowView: View {
    let site: MonitoredWebsite
    let isSelected: Bool
    let effectiveAccentColor: Color?
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    @State private var isHovered = false
    @State private var isDeleteHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill((effectiveAccentColor ?? .accentColor).opacity(site.isEnabled ? 0.15 : 0.05))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundStyle(site.isEnabled ? (effectiveAccentColor ?? .accentColor) : .secondary)
            }
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isHovered)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(site.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                
                Text(site.domain)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { site.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(isDeleteHovered ? .red : .red.opacity(0.8))
                    .scaleEffect(isDeleteHovered ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isDeleteHovered)
            }
            .buttonStyle(.plain)
            .onHover { isDeleteHovered = $0 }
            .help("Supprimer")
            .padding(.leading, 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.035)))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .offset(y: isHovered ? -0.5 : 0)
    }
}

// MARK: - Website Suggestion Row

struct WebsiteSuggestionRow: View {
    let suggestion: MonitoredWebsite
    let alreadyAdded: Bool
    let effectiveAccentColor: Color?
    let onAdd: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill((effectiveAccentColor ?? .accentColor).opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "globe")
                    .foregroundStyle(effectiveAccentColor ?? .accentColor)
                    .font(.system(size: 14))
            }
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isHovered)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(suggestion.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                
                Text(suggestion.domain)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if alreadyAdded {
                Label("Ajoutée", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button("Ajouter", action: onAdd)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .appleHoverEffect(scale: 1.05, liftOffset: -0.5, hoverTintOpacity: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
    }
}
