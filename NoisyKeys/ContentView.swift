//
//  ContentView.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import SwiftUI

struct ContentView: View {
    let controller: KeyboardNoiseController

    @State private var showsDebugReadouts = false

    private let presetColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var presetModes: [KeyboardSoundMode] {
        controller.availableSoundModes.filter { $0 != .customMix }
    }

    var body: some View {
        ZStack {
            NoisyBackgroundView(mode: controller.selectedSoundMode)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeroStageCard(controller: controller)

                    SoundPickerCard(
                        presetModes: presetModes,
                        selectedMode: controller.selectedSoundMode,
                        onSelectMode: controller.setSoundMode
                    )

                    HStack(alignment: .top, spacing: 18) {
                        NoiseSwitchCard(controller: controller)
                            .frame(width: 320)

                        TypingDashboardCard(controller: controller)
                    }

                    if controller.selectedSoundMode == .customMix {
                        CustomMixCard(controller: controller)
                    } else {
                        PlayGuideCard(controller: controller)
                    }

                    if NoisyKeysBuildOptions.showsDebugReadouts {
                        DebugShelf(
                            isExpanded: $showsDebugReadouts,
                            controller: controller
                        )
                    }
                }
                .padding(28)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 860, minHeight: 680)
    }
}

private struct HeroStageCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        HStack(alignment: .top, spacing: 26) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tiny piano chaos for all ages")
                    .font(.caption.weight(.bold))
                    .kerning(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.inkPrimary.opacity(0.54))

                Text("Noisy Keys")
                    .font(.noisyDisplay(size: 54))
                    .foregroundStyle(Color.inkPrimary)

                Text("A silly little piano toy for your keyboard. Fun for kids, charming for adults, and simple enough to start using right away.")
                    .font(.title3)
                    .foregroundStyle(Color.inkPrimary.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    StatusBadge(
                        icon: "dot.radiowaves.left.and.right",
                        label: "Scope",
                        value: controller.monitoringScope,
                        tint: .poolAccent
                    )

                    StatusBadge(
                        icon: "sparkles",
                        label: "Now Playing",
                        value: controller.selectedSoundMode.displayName,
                        tint: controller.selectedSoundMode.accentColor
                    )

                    StatusBadge(
                        icon: "speedometer",
                        label: "Speed",
                        value: controller.currentTempoDescription,
                        tint: .mintAccent
                    )
                }

                HStack(spacing: 10) {
                    StickerPill(
                        text: controller.selectedSoundMode.stickerCopy,
                        tint: controller.selectedSoundMode.accentColor
                    )

                    StickerPill(
                        text: controller.selectedProfileDisplayName,
                        tint: .butterAccent
                    )
                }

                Text(controller.selectedProfileSummary)
                    .font(.callout)
                    .foregroundStyle(Color.inkPrimary.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            StageMonitorCard(
                mode: controller.selectedSoundMode,
                isEnabled: controller.isNoiseEnabled,
                performanceDescription: controller.performanceDescription,
                totalKeyPresses: controller.totalKeyPresses
            )
            .frame(width: 310)
        }
        .noisyCard(tint: controller.selectedSoundMode.accentColor)
    }
}

private struct StageMonitorCard: View {
    let mode: KeyboardSoundMode
    let isEnabled: Bool
    let performanceDescription: String
    let totalKeyPresses: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Mini Stage")
                    .font(.headline)

                Spacer()

                Text(isEnabled ? "LIVE" : "NAP")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((isEnabled ? Color.mintAccent : Color.softOutline).opacity(0.34))
                    )
            }

            SignalMeter(mode: mode, seed: totalKeyPresses, isEnabled: isEnabled)
                .frame(height: 128)

            Text(performanceDescription)
                .font(.headline)
                .foregroundStyle(Color.inkPrimary.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            Text(isEnabled
                 ? "Fast typing should feel like a playful streak, not a panic attack."
                 : "Wake it back up when you want the keyboard acting ridiculous again.")
                .font(.callout)
                .foregroundStyle(Color.inkPrimary.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.panelBackground.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(mode.accentColor.opacity(0.24), lineWidth: 1.2)
        )
    }
}

private struct SoundPickerCard: View {
    let presetModes: [KeyboardSoundMode]
    let selectedMode: KeyboardSoundMode
    let onSelectMode: (KeyboardSoundMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                eyebrow: "Choose your piano mood",
                title: "Pick a preset or make your own",
                detail: "The four presets are the quick good choices. Custom Mix lets you mess with the piano without turning the app into a cockpit."
            )

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(presetModes) { mode in
                    SoundModeButton(
                        mode: mode,
                        isSelected: mode == selectedMode
                    ) {
                        onSelectMode(mode)
                    }
                }
            }

            CustomMixStrip(
                isSelected: selectedMode == .customMix,
                action: { onSelectMode(.customMix) }
            )
        }
        .noisyCard(tint: selectedMode.accentColor)
    }
}

private struct SoundModeButton: View {
    let mode: KeyboardSoundMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(mode.accentColor.opacity(0.18))
                            .frame(width: 54, height: 54)

                        Image(systemName: mode.symbolName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.inkPrimary)
                    }

                    Spacer()

                    Text(isSelected ? "LIVE" : "TAP")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(mode.accentColor.opacity(isSelected ? 0.28 : 0.14))
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.displayName)
                        .font(.title3.weight(.bold))

                    Text(mode.stickerCopy)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode.accentColor)

                    Text(mode.summary)
                        .font(.callout)
                        .foregroundStyle(Color.inkPrimary.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(NoisyModeTileStyle(tint: mode.accentColor, isSelected: isSelected))
    }
}

private struct CustomMixStrip: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.mintAccent.opacity(0.18))
                        .frame(width: 54, height: 54)

                    Image(systemName: "slider.horizontal.3")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.inkPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Mix")
                        .font(.title3.weight(.bold))

                    Text("Choose your own pitch, tone, and vibe.")
                        .font(.callout)
                        .foregroundStyle(Color.inkPrimary.opacity(0.68))
                }

                Spacer()

                Text(isSelected ? "LIVE" : "OPEN")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.mintAccent.opacity(isSelected ? 0.28 : 0.14))
                    )
            }
        }
        .buttonStyle(NoisyModeTileStyle(tint: .mintAccent, isSelected: isSelected))
    }
}

private struct NoiseSwitchCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                eyebrow: "Power",
                title: "Keyboard sound",
                detail: controller.hasGlobalAccess ? "" : "Finish setup to use Noisy Keys anywhere on your Mac."
            )

            Toggle(isOn: Binding(
                get: { controller.isNoiseEnabled },
                set: { controller.setNoiseEnabled($0) }
            )) {
                Text("Keyboard sound")
                    .font(.headline)
                    .foregroundStyle(Color.inkPrimary)
            }
            .toggleStyle(.switch)

            HStack(spacing: 12) {
                if !controller.hasGlobalAccess {
                    Button("Enable Access") {
                        controller.refreshAccessStatus(promptIfNeeded: true)
                    }
                    .buttonStyle(NoisyArcadeButtonStyle(fill: .butterAccent))
                }

                Button("Play Test") {
                    controller.playTestNoise()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .tomatoAccent))
            }

            if !controller.hasGlobalAccess {
                Text(controller.accessMessage)
                    .font(.callout)
                    .foregroundStyle(Color.inkPrimary.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .noisyCard(tint: controller.isNoiseEnabled ? .mintAccent : .softOutline)
    }
}

private struct TypingDashboardCard: View {
    let controller: KeyboardNoiseController

    private var champion: AdaptiveKeyStat? {
        controller.topKeyStats.first
    }

    private var sessionSummary: String {
        guard !controller.topKeyStats.isEmpty else {
            return "Type a little and your most-used keys will light up here."
        }

        let favorites = controller.topKeyStats
            .prefix(5)
            .map { "\($0.label)\($0.count)" }
            .joined(separator: " · ")
        return "Session favorites: \(favorites)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                eyebrow: "Typing Dashboard",
                title: "Your keyboard habits",
                detail: "A tiny playful dashboard for speed, streak, and the keys you hit the most."
            )

            HStack(spacing: 12) {
                DashboardStat(
                    title: "Speed",
                    value: controller.currentTempoDescription,
                    tint: .poolAccent
                )

                DashboardStat(
                    title: "Taps",
                    value: "\(controller.totalKeyPresses)",
                    tint: .butterAccent
                )

                DashboardStat(
                    title: "Top Key",
                    value: champion.map { "\($0.label) \($0.count)" } ?? "Warming up",
                    tint: .mintAccent
                )
            }

            KeyboardHeatMap(stats: controller.topKeyStats)

            Text(sessionSummary)
                .font(.callout)
                .foregroundStyle(Color.inkPrimary.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
        .noisyCard(tint: .poolAccent)
    }
}

private struct PlayGuideCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                eyebrow: "How it works",
                title: "Keep the toy-piano energy, lose the chaos",
                detail: "The presets stay playful, but the piano engine underneath is still trying to stay smooth and musical."
            )

            HStack(alignment: .top, spacing: 14) {
                GuideRow(
                    tint: controller.selectedSoundMode.accentColor,
                    icon: "music.note.house.fill",
                    title: "Pick one mood and stay there",
                    detail: controller.selectedSoundMode.displayName + " keeps one clear piano vibe instead of flipping around too fast."
                )

                GuideRow(
                    tint: .mintAccent,
                    icon: "keyboard.fill",
                    title: "Type like normal",
                    detail: "Slow typing should feel softer. Fast typing should feel more excited without turning into soup."
                )

                GuideRow(
                    tint: .poolAccent,
                    icon: "hand.tap.fill",
                    title: "Use Test Noise when in doubt",
                    detail: "If the Mac goes quiet, tap the test button first. That tells you whether the piano path is alive."
                )
            }
        }
        .noisyCard(tint: .butterAccent)
    }
}

private struct CustomMixCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                eyebrow: "Custom Mix",
                title: "Build your own piano potion",
                detail: controller.customPianoSettings.summary
            )

            HStack(alignment: .top, spacing: 18) {
                CustomSelectorRow(
                    title: "Pitch",
                    detail: controller.customPianoSettings.pitch.summary,
                    selection: Binding(
                        get: { controller.customPianoSettings.pitch },
                        set: { controller.setCustomPianoPitch($0) }
                    ),
                    options: CustomPianoPitch.allCases
                )

                CustomSelectorRow(
                    title: "Tone",
                    detail: controller.customPianoSettings.tone.summary,
                    selection: Binding(
                        get: { controller.customPianoSettings.tone },
                        set: { controller.setCustomPianoTone($0) }
                    ),
                    options: CustomPianoTone.allCases
                )

                CustomSelectorRow(
                    title: "Vibe",
                    detail: controller.customPianoSettings.vibe.summary,
                    selection: Binding(
                        get: { controller.customPianoSettings.vibe },
                        set: { controller.setCustomPianoVibe($0) }
                    ),
                    options: CustomPianoVibe.allCases
                )
            }
        }
        .noisyCard(tint: .mintAccent)
    }
}

private struct DebugShelf: View {
    @Binding var isExpanded: Bool
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(isExpanded ? "Hide Debug Stuff" : "Show Debug Stuff") {
                isExpanded.toggle()
            }
            .buttonStyle(NoisyArcadeButtonStyle(fill: .softOutline))
            .frame(width: 220)

            if isExpanded {
                DebugReadoutCard(controller: controller)
            }
        }
    }
}

private struct DebugReadoutCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(
                eyebrow: "Debug",
                title: "Nerdy piano readouts",
                detail: "Kept out of the product view unless you explicitly open it."
            )

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                FactPill(
                    label: "Profile",
                    value: controller.selectedProfileDisplayName,
                    tint: controller.selectedSoundMode.accentColor
                )

                FactPill(
                    label: "Performance",
                    value: controller.performanceDescription,
                    tint: .butterAccent
                )

                FactPill(
                    label: "Last Event",
                    value: controller.lastEventDescription,
                    tint: .mintAccent,
                    monospaced: true
                )

                FactPill(
                    label: "Last Sound Slot",
                    value: controller.lastSoundIdentifier,
                    tint: .tomatoAccent,
                    monospaced: true
                )

                FactPill(
                    label: "Top Letters",
                    value: controller.learnedKeysDescription,
                    tint: .midnightAccent,
                    monospaced: true
                )

                FactPill(
                    label: "Mapping Vibe",
                    value: controller.adaptiveMappingDescription,
                    tint: .softOutline
                )
            }
        }
        .noisyCard(tint: .softOutline)
    }
}

private struct GuideRow: View {
    let tint: Color
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.inkPrimary)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.18))
                )

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.inkPrimary)

            Text(detail)
                .font(.callout)
                .foregroundStyle(Color.inkPrimary.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SectionTitle: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.54))

            Text(title)
                .font(.noisyDisplay(size: 28))
                .foregroundStyle(Color.inkPrimary)

            if !detail.isEmpty {
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.inkPrimary.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct StickerPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.inkPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.18))
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.24), lineWidth: 1)
            )
    }
}

private struct FactPill: View {
    let label: String
    let value: String
    let tint: Color
    var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .kerning(1)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.58))

            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .foregroundStyle(Color.inkPrimary.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.30), lineWidth: 1.1)
        )
    }
}

private struct DashboardStat: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(1)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.58))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct StatusBadge: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.inkPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(tint.opacity(0.22))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.inkPrimary.opacity(0.58))

                Text(value)
                    .font(.headline)
                    .foregroundStyle(Color.inkPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.panelBackground.opacity(0.94))
        )
        .overlay(
            Capsule()
                .stroke(Color.softOutline.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct SignalMeter: View {
    let mode: KeyboardSoundMode
    let seed: Int
    let isEnabled: Bool

    private var barHeights: [CGFloat] {
        (0..<7).map { index in
            let energy = max(seed, 1)
            let value = (energy * (index + 3) + (index * 17)) % 72
            return CGFloat(38 + value)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.inkPrimary.opacity(0.08))

            Circle()
                .fill(mode.accentColor.opacity(0.24))
                .frame(width: 120, height: 120)
                .offset(x: 162, y: -42)

            Circle()
                .fill(Color.butterAccent.opacity(0.22))
                .frame(width: 78, height: 78)
                .offset(x: 18, y: -22)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill((index.isMultiple(of: 2) ? mode.accentColor : Color.tomatoAccent).opacity(isEnabled ? 0.94 : 0.28))
                        .frame(width: 24, height: isEnabled ? height : 26)
                }
            }
            .padding(18)

            HStack(spacing: 8) {
                Image(systemName: "music.note")
                Text("tap tap tap")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.inkPrimary.opacity(0.70))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.panelBackground.opacity(0.94))
            )
            .padding(14)
        }
        .clipped()
    }
}

private struct KeyboardHeatMap: View {
    let stats: [AdaptiveKeyStat]

    private let rows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]

    private var counts: [String: Int] {
        Dictionary(uniqueKeysWithValues: stats.map { ($0.label, $0.count) })
    }

    private var maxCount: Double {
        Double(stats.map(\.count).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hot Keys")
                .font(.caption.weight(.bold))
                .kerning(1)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.58))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 8) {
                        if index == 1 {
                            Spacer(minLength: 20)
                        } else if index == 2 {
                            Spacer(minLength: 42)
                        }

                        ForEach(row, id: \.self) { key in
                            HeatKey(
                                label: key,
                                count: counts[key] ?? 0,
                                maxCount: maxCount
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct HeatKey: View {
    let label: String
    let count: Int
    let maxCount: Double

    private var tint: Color {
        guard count > 0 else { return .softOutline.opacity(0.34) }
        let intensity = min(Double(count) / maxCount, 1)
        if intensity > 0.66 {
            return .tomatoAccent.opacity(0.86)
        }
        if intensity > 0.33 {
            return .butterAccent.opacity(0.84)
        }
        return .mintAccent.opacity(0.80)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.inkPrimary)
            Text(count == 0 ? " " : "\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.inkPrimary.opacity(0.62))
        }
        .frame(width: 38, height: 42)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.inkPrimary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct CustomSelectorRow<Option: CaseIterable & Hashable & Identifiable>: View where Option.AllCases: RandomAccessCollection, Option: CustomStringConvertible {
    let title: String
    let detail: String
    @Binding var selection: Option
    let options: Option.AllCases

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.inkPrimary)

            Picker(title, selection: $selection) {
                ForEach(Array(options), id: \.id) { option in
                    Text(option.description).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Text(detail)
                .font(.callout)
                .foregroundStyle(Color.inkPrimary.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NoisyBackgroundView: View {
    let mode: KeyboardSoundMode

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.panelBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.butterAccent.opacity(0.24))
                .frame(width: 360, height: 360)
                .blur(radius: 30)
                .offset(x: -280, y: -220)

            Circle()
                .fill(mode.accentColor.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 26)
                .offset(x: 310, y: -180)

            Circle()
                .fill(Color.poolAccent.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 22)
                .offset(x: 280, y: 250)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView(controller: KeyboardNoiseController())
}
