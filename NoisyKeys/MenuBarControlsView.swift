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
        Group {
            Text(controller.isNoiseEnabled ? "Noise On" : "Noise Off")
            Text(controller.monitoringScope)
            Text(controller.selectedSoundMode.displayName)
            Text(controller.selectedSoundModeSummary)
            Toggle("Keyboard sounds enabled", isOn: Binding(
                get: { controller.isNoiseEnabled },
                set: { controller.setNoiseEnabled($0) }
            ))

            Button("Check Access Again") {
                controller.refreshAccessStatus(promptIfNeeded: true)
            }

            Divider()

            ForEach(controller.availableSoundModes) { mode in
                Button {
                    controller.setSoundMode(mode)
                } label: {
                    HStack {
                        Text(mode.displayName)
                        Spacer()
                        if mode == controller.selectedSoundMode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button("Test Noise") {
                controller.playTestNoise()
            }

            Divider()

            Button("Quit NoisyKeys") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
