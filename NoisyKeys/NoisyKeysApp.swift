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

        MenuBarExtra(
            "NoisyKeys",
            systemImage: keyboardNoiseController.isNoiseEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
        ) {
            MenuBarControlsView(controller: keyboardNoiseController)
        }
        .menuBarExtraStyle(.window)
    }
}
