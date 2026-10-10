//
//  DisplaysTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

enum DisplaySubTab: String, CaseIterable, Identifiable {
    case brightness = "brightness"
    case calibration = "calibration"
    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .brightness: return "Luminosité"
        case .calibration: return "Calibrage"
        }
    }
}

struct DisplaysTab: View {
    @Bindable var settings: AppSettings
    @State private var selectedSubTab: DisplaySubTab = .brightness

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedSubTab) {
                ForEach(DisplaySubTab.allCases) { tab in
                    Text(tab.displayName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()

            Group {
                switch selectedSubTab {
                case .brightness:
                    BrightnessTab(settings: settings)
                case .calibration:
                    CalibrationTab(settings: settings)
                }
            }
        }
    }
}
