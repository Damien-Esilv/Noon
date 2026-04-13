//
//  MonitoredAppsTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import UniformTypeIdentifiers

struct MonitoredAppsTab: View {
    @Bindable var settings: AppSettings
    
    @State private var showFilePicker = false
    @State private var showSuggestions = false
    @State private var searchText = ""
    @State private var selectedApp: MonitoredApp?
    
    private var filteredApps: [MonitoredApp] {
        if searchText.isEmpty {
            return settings.monitoredApps
        }
        return settings.monitoredApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Toolbar
            toolbarSection
            
            Divider()
            
            // MARK: - App List
            if settings.monitoredApps.isEmpty {
                emptyStateView
            } else {
                appListView
            }
            
            // MARK: - Errors Banner
            if !settings.invalidApps.isEmpty {
                errorBanner
            }
        }
        .sheet(isPresented: $showSuggestions) {
            suggestionsSheet
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.applicationBundle],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }
    
    // MARK: - Toolbar
    
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
            .buttonStyle(.bordered)
            .help("Suggestions d'apps")
            
            // Add from file browser
            Button {
                showFilePicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13))
                    .frame(width: 14)
            }
            .buttonStyle(.bordered)
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
            .buttonStyle(.bordered)
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
            
            Text("Aucune app surveillée")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text("Ajoutez des applications créatives pour que Noon\ndésactive automatiquement True Tone et Night Shift.")
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
                
                Button {
                    showFilePicker = true
                } label: {
                    Label("Parcourir", systemImage: "folder")
                }
                .buttonStyle(.bordered)
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
                                    withAnimation(.spring(response: 0.3)) {
                                        settings.addApp(suggestion)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .frame(width: 480, height: 400)
    }
    
    // MARK: - File Import
    
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
                
                withAnimation(.spring(response: 0.3)) {
                    settings.addApp(app)
                }
            }
            
        case .failure(let error):
            print("[Noon] File import error: \(error.localizedDescription)")
        }
    }
}
