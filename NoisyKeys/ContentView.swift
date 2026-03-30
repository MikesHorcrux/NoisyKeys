//
//  ContentView.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import SwiftUI

struct ContentView: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Noisy Keys")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))

                Text("Every key tap makes noise. Keep the app running, allow keyboard listening, and your Mac gets a little more unhinged.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                StatusCard(
                    title: "Scope",
                    value: controller.monitoringScope,
                    detail: controller.accessMessage
                )

                StatusCard(
                    title: "Clacks",
                    value: "\(controller.totalKeyPresses)",
                    detail: controller.lastEventDescription
                )

                StatusCard(
                    title: "Music",
                    value: controller.selectedInstrument.displayName,
                    detail: controller.currentTempoDescription
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Last Event")
                    .font(.headline)

                Text(controller.lastEventDescription)
                    .font(.system(.title3, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Sound Mapping")
                    .font(.headline)

                Picker("Instrument", selection: Binding(
                    get: { controller.selectedInstrument },
                    set: { controller.setInstrument($0) }
                )) {
                    ForEach(KeyboardInstrument.allCases) { instrument in
                        Text(instrument.displayName)
                            .tag(instrument)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Last Sound Slot")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(controller.lastSoundIdentifier)
                        .font(.system(.body, design: .monospaced))
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Performance State")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(controller.performanceDescription)
                        .font(.system(.body, design: .monospaced))
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Learned Top Letters")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(controller.learnedKeysDescription)
                        .font(.system(.body, design: .monospaced))
                }

                Text(controller.adaptiveMappingDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("Piano now reacts to typing speed and tone, and the sound slot string is still the stable hook if we swap to our own packs later.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Text("Noise Switch")
                    .font(.headline)

                Toggle(isOn: Binding(
                    get: { controller.isNoiseEnabled },
                    set: { controller.setNoiseEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(controller.isNoiseEnabled ? "Keyboard sounds are on" : "Keyboard sounds are off")
                            .font(.title3.weight(.semibold))

                        Text(controller.isNoiseEnabled
                             ? "Turn this off when the bit stops being funny."
                             : "Turn this back on when you want the goblin energy again.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 12) {
                Button("Check Access Again") {
                    controller.refreshAccessStatus(promptIfNeeded: true)
                }
                .buttonStyle(.borderedProminent)

                Button("Test Noise") {
                    controller.playTestNoise()
                }
                .buttonStyle(.bordered)
            }

            Text("Modifier keys count too. Held-repeat keyDown events are ignored so the app reacts to taps, not key-repeat spam.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(minWidth: 760, minHeight: 520, alignment: .topLeading)
    }
}

#Preview {
    ContentView(controller: KeyboardNoiseController())
}

private struct StatusCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
