//
//  HUDOverlayController.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import AppKit

@MainActor
public final class HUDOverlayController {
    public static let shared = HUDOverlayController()

    private var panel: NSPanel?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    public func showHUD(
        isCreativeMode: Bool,
        activePreset: AppleReferencePreset? = nil,
        is100NitsLocked: Bool = false,
        isLightingDriftExceeded: Bool = false,
        driftPercentage: Double = 0.0,
        autoDismissDelay: TimeInterval = 2.5
    ) {
        dismissTask?.cancel()

        let hudView = DynamicHUDView(
            isCreativeMode: isCreativeMode,
            activePreset: activePreset,
            is100NitsLocked: is100NitsLocked,
            isLightingDriftExceeded: isLightingDriftExceeded,
            driftPercentage: driftPercentage
        )

        let hostingView = NSHostingView(rootView: hudView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layoutSubtreeIfNeeded()
        let fittingSize = hostingView.fittingSize

        let targetPanel: NSPanel
        if let existing = panel {
            targetPanel = existing
            existing.contentView = hostingView
        } else {
            let newPanel = NSPanel(
                contentRect: NSRect(origin: .zero, size: fittingSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = false
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
            newPanel.contentView = hostingView
            self.panel = newPanel
            targetPanel = newPanel
        }

        // Position under the menu bar / notch on the main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (fittingSize.width / 2.0)
            let y = screen.frame.maxY - fittingSize.height - 28 // 28pt below top edge
            targetPanel.setFrame(NSRect(x: x, y: y, width: fittingSize.width, height: fittingSize.height), display: true)
        }

        targetPanel.alphaValue = 0.0
        targetPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            targetPanel.animator().alphaValue = 1.0
        }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                targetPanel.animator().alphaValue = 0.0
            }, completionHandler: {
                if targetPanel.alphaValue == 0.0 {
                    targetPanel.orderOut(nil)
                }
            })
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        panel?.orderOut(nil)
    }
}
