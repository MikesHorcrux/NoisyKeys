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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(controller.isNoiseEnabled ? "Noise On" : "Noise Off", systemImage: controller.isNoiseEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.headline)

            Text(controller.monitoringScope)
                .font(.subheadline.weight(.semibold))

            Text(controller.accessMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Keyboard sounds enabled", isOn: Binding(
                get: { controller.isNoiseEnabled },
                set: { controller.setNoiseEnabled($0) }
            ))

            HStack(spacing: 10) {
                Button("Check Access Again") {
                    controller.refreshAccessStatus(promptIfNeeded: true)
                }

                Button("Test Noise") {
                    controller.playTestNoise()
                }
            }

            Divider()

            Button("Quit NoisyKeys") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
    }
}
