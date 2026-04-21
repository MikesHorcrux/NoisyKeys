//
//  SettingsScreen.swift
//  NoisyKeys
//

import SwiftUI

struct SettingsScreen: View {
    @ObservedObject var controller: KeyboardNoiseController

    var body: some View {
        TabView {
            GeneralSettingsPane(controller: controller)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            SoundSettingsPane(controller: controller)
                .tabItem {
                    Label("Sound", systemImage: "music.note")
                }

            VibeSettingsPane(controller: controller)
                .tabItem {
                    Label("Vibe", systemImage: "sparkles")
                }
        }
        .frame(width: 540, height: 430)
        .scenePadding()
    }
}

private struct GeneralSettingsPane: View {
    @ObservedObject var controller: KeyboardNoiseController

    var body: some View {
        Form {
            Section("Playback") {
                Toggle(isOn: Binding(
                    get: { controller.isNoiseEnabled },
                    set: { controller.setNoiseEnabled($0) }
                )) {
                    Text("Keyboard sound")
                }

                LabeledContent("Monitoring") {
                    Text(controller.monitoringScope)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("System-wide access") {
                    Text(controller.hasGlobalAccess ? "Active" : "Needs access")
                        .foregroundStyle(controller.hasGlobalAccess ? .secondary : Color.tomatoAccent)
                }
            }

            Section("System Access") {
                Text(controller.accessMessage)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("Open System Settings") {
                        controller.openInputMonitoringSettings()
                    }

                    Button("Check Again") {
                        controller.checkAccessAgain()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}

private struct SoundSettingsPane: View {
    @ObservedObject var controller: KeyboardNoiseController

    var body: some View {
        Form {
            Section("Sound Mode") {
                Picker("Sound", selection: Binding(
                    get: { controller.selectedSoundMode },
                    set: { controller.selectSoundMode($0, previewSelection: true) }
                )) {
                    ForEach(KeyboardSoundMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(controller.selectedProfileSummary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Preview Sound") {
                    controller.previewSelectedSound()
                }
            }

            Section("Custom Mix") {
                if controller.selectedSoundMode == .customMix {
                    Picker("Pitch", selection: Binding(
                        get: { controller.customPianoSettings.pitch },
                        set: { controller.setCustomPianoPitch($0) }
                    )) {
                        ForEach(CustomPianoPitch.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Tone", selection: Binding(
                        get: { controller.customPianoSettings.tone },
                        set: { controller.setCustomPianoTone($0) }
                    )) {
                        ForEach(CustomPianoTone.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Vibe", selection: Binding(
                        get: { controller.customPianoSettings.vibe },
                        set: { controller.setCustomPianoVibe($0) }
                    )) {
                        ForEach(CustomPianoVibe.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    LabeledContent("Saved mix") {
                        Text(controller.customPianoSettings.summary)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }

                    Button("Edit Custom Mix") {
                        controller.selectSoundMode(.customMix, previewSelection: true)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}

private struct VibeSettingsPane: View {
    @ObservedObject var controller: KeyboardNoiseController

    var body: some View {
        Form {
            Section("Vibe Detection") {
                Toggle(isOn: Binding(
                    get: { controller.isVibeDetectionEnabled },
                    set: { controller.setVibeDetectionEnabled($0) }
                )) {
                    Text("Adapt sound to typing vibe")
                }

                LabeledContent("Status") {
                    Text(controller.vibeStatusDescription)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Analyzer") {
                Picker("Mode", selection: Binding(
                    get: { controller.vibeAnalysisMode },
                    set: { controller.setVibeAnalysisMode($0) }
                )) {
                    ForEach(VibeAnalysisMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!controller.isVibeDetectionEnabled)
            }

            Section("Response") {
                Picker("Intensity", selection: Binding(
                    get: { controller.vibeResponseIntensity },
                    set: { controller.setVibeResponseIntensity($0) }
                )) {
                    ForEach(TypingVibeResponseIntensity.allCases) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!controller.isVibeDetectionEnabled)
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}

#Preview {
    SettingsScreen(controller: KeyboardNoiseController())
}
