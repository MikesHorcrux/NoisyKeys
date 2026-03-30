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

    @MainActor
    @Test func musicEngineMapsLettersToStableSoundSlots() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        let input = KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        )

        let plan = engine.plan(for: input)

        #expect(plan.role == .melody)
        #expect(plan.noteLabel == "C4")
        #expect(plan.soundID == "piano.melody.a.c4")
    }

    @MainActor
    @Test func cadenceTrackerRaisesIntensityForFastTyping() {
        var tracker = TypingCadenceTracker()

        _ = tracker.register(at: Date(timeIntervalSinceReferenceDate: 0))
        let snapshot = tracker.register(at: Date(timeIntervalSinceReferenceDate: 0.3))

        #expect(snapshot.beatsPerMinute == 200)
        #expect(snapshot.intensity == .energetic)
    }

    @MainActor
    @Test func translatorUsesUSANSIKeyCodesForGlobalInputs() {
        let input = KeyboardInputTranslator.input(
            for: .keyDown,
            keyCode: 49,
            source: .systemWide,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        )

        #expect(input?.symbol == .space)
    }

    @Test func noteFrequencyParsesNamedNotes() {
        let c4 = KeyboardNoteFrequency.hz(for: "C4")
        let f4 = KeyboardNoteFrequency.hz(for: "F4")

        #expect(c4 != nil)
        #expect(f4 != nil)
        #expect(c4! < f4!)
    }

}
