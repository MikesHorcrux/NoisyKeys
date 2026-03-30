//
//  NoisyKeysApp.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import SwiftUI

@main
struct NoisyKeysApp: App {
    @State private var keyboardNoiseController = KeyboardNoiseController()

    var body: some Scene {
        WindowGroup {
            ContentView(controller: keyboardNoiseController)
                .task {
                    keyboardNoiseController.start()
                }
        }

        MenuBarExtra(isInserted: .constant(true)) {
            MenuBarControlsView(controller: keyboardNoiseController)
        } label: {
            Label(
                "NoisyKeys",
                systemImage: keyboardNoiseController.isNoiseEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
