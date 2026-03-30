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
        .frame(minWidth: 680, minHeight: 420, alignment: .topLeading)
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
