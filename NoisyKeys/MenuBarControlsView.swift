//
//  MenuBarControlsView.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import AppKit
import SwiftUI

struct MenuBarControlsView: View {
    let controller: KeyboardNoiseController

    private let modeColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var topKeyLabel: String {
        controller.topKeyStats.first?.label ?? "None"
    }

    var body: some View {
        ZStack {
            MenuBarBackdrop(mode: controller.selectedSoundMode)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    MenuBarHeroCard(
                        controller: controller,
                        topKeyLabel: topKeyLabel
                    )

                    MenuBarQuickControlsCard(controller: controller)

                    MenuBarModesCard(
                        controller: controller,
                        columns: modeColumns
                    )

                    MenuBarFooterRow(
                        openApp: bringAppForward
                    )
                }
                .padding(16)
                .frame(width: 356)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func bringAppForward() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApp.windows.first(where: { !$0.isMiniaturized && $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

private struct MenuBarHeroCard: View {
    let controller: KeyboardNoiseController
    let topKeyLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(controller.selectedSoundMode.accentColor.opacity(0.18))
                        .frame(width: 48, height: 48)

                    NoisyMenuBarGlyph(isEnabled: controller.isNoiseEnabled)
                        .frame(width: 24, height: 18)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Noisy Keys")
                        .font(.noisyDisplay(size: 26))
                        .foregroundStyle(Color.inkPrimary)

                    Text(controller.hasGlobalAccess
                         ? (controller.isNoiseEnabled ? "Keyboard sound is on." : "Keyboard sound is off.")
                         : "Keyboard access needed.")
                        .font(.callout)
                        .foregroundStyle(Color.inkPrimary.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(controller.isNoiseEnabled ? "LIVE" : "OFF")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((controller.isNoiseEnabled ? Color.mintAccent : Color.softOutline).opacity(0.28))
                    )
            }

            HStack(spacing: 8) {
                MenuBarStatPill(
                    title: "Mood",
                    value: controller.selectedSoundMode.displayName,
                    tint: controller.selectedSoundMode.accentColor
                )

                MenuBarStatPill(
                    title: "Speed",
                    value: controller.currentTempoDescription,
                    tint: .poolAccent
                )

                MenuBarStatPill(
                    title: "Top Key",
                    value: topKeyLabel,
                    tint: .butterAccent
                )
            }

            Text(controller.selectedProfileSummary)
                .font(.callout)
                .foregroundStyle(Color.inkPrimary.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
        .noisyCard(tint: controller.selectedSoundMode.accentColor)
    }
}

private struct MenuBarQuickControlsCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MenuBarSectionHeader(
                eyebrow: "Controls",
                title: "Sound"
            )

            Toggle(isOn: Binding(
                get: { controller.isNoiseEnabled },
                set: { controller.setNoiseEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keyboard sound")
                        .font(.headline)
                        .foregroundStyle(Color.inkPrimary)

                    Text(controller.monitoringScope)
                        .font(.caption)
                        .foregroundStyle(Color.inkPrimary.opacity(0.60))
                }
            }
            .toggleStyle(.switch)

            HStack(spacing: 10) {
                Button("Test Sound") {
                    controller.playTestNoise()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .tomatoAccent))
            }

            if !controller.hasGlobalAccess {
                PermissionGuidanceView(controller: controller, compact: true)
            }
        }
        .noisyCard(tint: controller.isNoiseEnabled ? .mintAccent : .softOutline)
    }
}

private struct MenuBarModesCard: View {
    let controller: KeyboardNoiseController
    let columns: [GridItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MenuBarSectionHeader(
                eyebrow: "Sounds",
                title: "Choose a sound"
            )

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(controller.availableSoundModes) { mode in
                    Button {
                        controller.setSoundMode(mode)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: mode.symbolName)
                                    .font(.headline.weight(.bold))
                                    .frame(width: 22, height: 22)

                                Spacer()

                                if mode == controller.selectedSoundMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.headline)
                                }
                            }

                            Text(mode.displayName)
                                .font(.subheadline.weight(.bold))

                            Text(mode == .customMix ? "Edit in app" : mode.stickerCopy)
                                .font(.caption)
                                .foregroundStyle(Color.inkPrimary.opacity(0.66))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(NoisyModeTileStyle(tint: mode.accentColor, isSelected: mode == controller.selectedSoundMode))
                }
            }
        }
        .noisyCard(tint: .poolAccent)
    }
}

private struct MenuBarFooterRow: View {
    let openApp: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button("Open App") {
                openApp()
            }
            .buttonStyle(NoisyArcadeButtonStyle(fill: .poolAccent))

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(NoisyArcadeButtonStyle(fill: .softOutline))
        }
    }
}

private struct MenuBarSectionHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .kerning(1.1)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.54))

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.inkPrimary)
        }
    }
}

private struct MenuBarStatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.56))

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct MenuBarBackdrop: View {
    let mode: KeyboardSoundMode

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.panelBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.butterAccent.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 20)
                .offset(x: -110, y: -130)

            Circle()
                .fill(mode.accentColor.opacity(0.14))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: 120, y: -70)
        }
    }
}
