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
            Image(nsImage: NoisyMenuBarStatusImage.make(isEnabled: keyboardNoiseController.isNoiseEnabled))
                .renderingMode(.template)
                .frame(width: 18, height: 14)
                .help("Noisy Keys")
        }
        .menuBarExtraStyle(.window)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 388, height: 520)
        .windowResizability(.contentSize)
    }
}
