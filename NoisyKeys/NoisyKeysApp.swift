//
//  NoisyKeysApp.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import SwiftUI

enum NoisyKeysWindowID {
    static let dashboard = "dashboard"
}

final class NoisyKeysAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct NoisyKeysApp: App {
    @NSApplicationDelegateAdaptor(NoisyKeysAppDelegate.self) private var appDelegate
    @StateObject private var keyboardNoiseController: KeyboardNoiseController

    init() {
        let controller = KeyboardNoiseController()
        controller.start()
        _keyboardNoiseController = StateObject(wrappedValue: controller)
    }

    var body: some Scene {
        WindowGroup("Noisy Keys", id: NoisyKeysWindowID.dashboard) {
            ContentView(controller: keyboardNoiseController)
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
