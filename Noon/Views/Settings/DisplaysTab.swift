//
//  DisplaysTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

enum DisplaySubTab: String, CaseIterable, Identifiable {
    case brightness = "Luminosité"
    case calibration = "Calibrage"
    var id: String { rawValue }
}

struct DisplaysTab: View {
    @Bindable var settings: AppSettings
    @State private var selectedSubTab: DisplaySubTab = .brightness

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedSubTab) {
                ForEach(DisplaySubTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
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
