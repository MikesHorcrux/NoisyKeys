//
//  NoisyKeysTests.swift
//  NoisyKeysTests
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import AppKit
import Testing
@testable import NoisyKeys

struct NoisyKeysTests {

    @MainActor
    @Test func keyDownOnlyTriggersForFreshPresses() async throws {
        #expect(KeyboardEventFilter.shouldPlay(for: .keyDown, isARepeat: false))
        #expect(!KeyboardEventFilter.shouldPlay(for: .keyDown, isARepeat: true))
    }

    @MainActor
    @Test func modifierChangesAlsoTriggerNoise() async throws {
        #expect(KeyboardEventFilter.shouldPlay(for: .flagsChanged, isARepeat: false))
        #expect(!KeyboardEventFilter.shouldPlay(for: .leftMouseDown, isARepeat: false))
    }

}
