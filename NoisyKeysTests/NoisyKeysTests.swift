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
        #expect(plan.soundID == "piano-warm-felt.melody.a.c4")
        #expect(plan.profile.displayName == "Warm Felt")
        #expect(plan.noteFamilyName == "Home")
        #expect(plan.learnedRank == 0)
    }

    @MainActor
    @Test func presetCatalogsExposeEightProfilesPerInstrument() {
        #expect(PianoProfileCatalog.all.count == 8)
        #expect(LoFiProfileCatalog.all.count == 8)
    }

    @MainActor
    @Test func soundModesStayLimitedToFiveSimpleChoices() {
        #expect(KeyboardSoundMode.allCases.count == 5)
        #expect(KeyboardSoundMode.allCases.map(\.displayName) == [
            "Grand Room",
            "Felt Bloom",
            "Jazz Club",
            "Midnight Blue",
            "Custom Mix"
        ])
    }

    @MainActor
    @Test func curatedSoundModesStayLimitedToFourPresets() {
        #expect(KeyboardSoundMode.curatedModes.count == 4)
        #expect(!KeyboardSoundMode.curatedModes.contains(.customMix))
        #expect(KeyboardSoundMode.defaultCuratedMode == .feltBloom)
    }

    @MainActor
    @Test func soundModeSwitchChangesInstrumentAndBackingProfile() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        engine.setSoundMode(.grandRoom)

        let grandPlan = engine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        #expect(grandPlan.instrument == .piano)
        #expect(grandPlan.profile.displayName == "Concert Hall")

        engine.setSoundMode(.midnightBlue)
        let midnightPlan = engine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 1)
        ))

        #expect(midnightPlan.instrument == .piano)
        #expect(midnightPlan.profile.displayName == "Moonlight")
    }

    @MainActor
    @Test func changingLoFiProfileChangesSoundPrefix() {
        var engine = KeyboardMusicEngine(instrument: .loFiKeys)
        engine.setCurrentProfile(id: "rain-window")

        let plan = engine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        #expect(plan.profile.displayName == "Rain Window")
        #expect(plan.soundID.hasPrefix("lofi-rain-window."))
    }

    @MainActor
    @Test func changingPianoProfileChangesSoundPrefix() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        engine.setCurrentProfile(id: "moonlight")

        let plan = engine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        #expect(plan.profile.displayName == "Moonlight")
        #expect(plan.soundID.hasPrefix("piano-moonlight."))
    }

    @MainActor
    @Test func customMixBuildsDynamicPianoProfile() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        engine.setSoundMode(.customMix)
        engine.setCustomPianoSettings(
            CustomPianoSettings(
                pitch: .high,
                tone: .bright,
                vibe: .dreamy
            )
        )

        let plan = engine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        #expect(plan.profile.displayName == "Custom Mix")
        #expect(plan.profile.id == CustomPianoProfileBuilder.profileID)
        #expect(engine.currentSoundMode == .customMix)
        #expect(engine.currentCustomPianoSettings.vibe == .dreamy)
    }

    @MainActor
    @Test func pianoUsesBroaderRegisterAcrossKeyboardColumns() {
        var leftEngine = KeyboardMusicEngine(instrument: .piano)
        let leftPlan = leftEngine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        var rightEngine = KeyboardMusicEngine(instrument: .piano)
        let rightPlan = rightEngine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 35,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        let leftMidi = KeyboardNoteFrequency.midiNote(for: leftPlan.noteLabel)
        let rightMidi = KeyboardNoteFrequency.midiNote(for: rightPlan.noteLabel)

        #expect(leftMidi != nil)
        #expect(rightMidi != nil)
        #expect(leftMidi! < rightMidi!)
    }

    @MainActor
    @Test func musicEngineLearnsFrequentLetters() {
        var engine = KeyboardMusicEngine(instrument: .piano)

        for offset in 0..<5 {
            let input = KeyboardInput(
                symbol: .letter("e"),
                keyCode: 14,
                source: .localApp,
                timestamp: Date(timeIntervalSinceReferenceDate: TimeInterval(offset))
            )
            _ = engine.plan(for: input)
        }

        let plan = engine.plan(for: KeyboardInput(
            symbol: .letter("e"),
            keyCode: 14,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 12)
        ))

        #expect(plan.learnedRank == 0)
        #expect(plan.noteFamilyName == "Home")
        #expect(engine.learnedKeysSummary.contains("E"))
    }

    @MainActor
    @Test func spaceContinuesTheCurrentPhrase() {
        var engine = KeyboardMusicEngine(instrument: .piano)

        let leadPlan = engine.plan(for: KeyboardInput(
            symbol: .letter("f"),
            keyCode: 3,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))

        let spacePlan = engine.plan(for: KeyboardInput(
            symbol: .space,
            keyCode: 49,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 1.0)
        ))

        #expect(leadPlan.role == .melody)
        #expect(spacePlan.role == .pulse)
        #expect(spacePlan.noteLabel == leadPlan.noteLabel)
        #expect(spacePlan.noteFamilyName == "Mellow Pulse")
    }

    @MainActor
    @Test func volumeStaysFlatAcrossKeys() {
        var engine = KeyboardMusicEngine(instrument: .piano)

        let letterPlan = engine.plan(for: KeyboardInput(
            symbol: .letter("a"),
            keyCode: 0,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))
        let spacePlan = engine.plan(for: KeyboardInput(
            symbol: .space,
            keyCode: 49,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 1.0)
        ))
        let punctuationPlan = engine.plan(for: KeyboardInput(
            symbol: .punctuation("."),
            keyCode: 47,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 2.0)
        ))

        #expect(letterPlan.velocity == spacePlan.velocity)
        #expect(spacePlan.velocity == punctuationPlan.velocity)
    }

    @MainActor
    @Test func fastSpacingStaysInThePhrasePulseRole() {
        var slowEngine = KeyboardMusicEngine(instrument: .piano)
        _ = slowEngine.plan(for: KeyboardInput(
            symbol: .letter("f"),
            keyCode: 3,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))
        let slowSpace = slowEngine.plan(for: KeyboardInput(
            symbol: .space,
            keyCode: 49,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 1.0)
        ))

        var fastEngine = KeyboardMusicEngine(instrument: .piano)
        _ = fastEngine.plan(for: KeyboardInput(
            symbol: .letter("f"),
            keyCode: 3,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))
        let fastSpace = fastEngine.plan(for: KeyboardInput(
            symbol: .space,
            keyCode: 49,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0.15)
        ))

        #expect(slowSpace.role == .pulse)
        #expect(fastSpace.role == .pulse)
        #expect(slowSpace.noteFamilyName == "Mellow Pulse")
        #expect(fastSpace.noteFamilyName == "Phrase Trail")
    }

    @MainActor
    @Test func slowHappyPhraseFeelsMellow() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        let sequence: [(KeyboardSymbol, TimeInterval)] = [
            (.letter("l"), 0),
            (.letter("o"), 1.2),
            (.letter("v"), 2.4),
            (.letter("e"), 3.6)
        ]

        let finalPlan = sequence.reduce(into: SoundTriggerPlan?.none) { currentPlan, step in
            currentPlan = engine.plan(for: KeyboardInput(
                symbol: step.0,
                keyCode: 0,
                source: .localApp,
                timestamp: Date(timeIntervalSinceReferenceDate: step.1)
            ))
        }

        #expect(finalPlan != nil)
        #expect(finalPlan?.textMood == .joyful)
        #expect(finalPlan?.performanceStyle == .mellow)
        #expect(finalPlan?.sustainPedalEngaged == true)
        #expect(engine.performanceDescription.contains("Felt Bloom"))
        #expect(engine.performanceDescription.contains("Mellow"))
    }

    @MainActor
    @Test func fastAngryPhraseFeelsStormy() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        let sequence: [(KeyboardSymbol, TimeInterval)] = [
            (.letter("f"), 0),
            (.letter("u"), 0.12),
            (.letter("c"), 0.24),
            (.letter("k"), 0.36),
            (.punctuation("!"), 0.48)
        ]

        let finalPlan = sequence.reduce(into: SoundTriggerPlan?.none) { currentPlan, step in
            currentPlan = engine.plan(for: KeyboardInput(
                symbol: step.0,
                keyCode: 0,
                source: .localApp,
                timestamp: Date(timeIntervalSinceReferenceDate: step.1)
            ))
        }

        #expect(finalPlan != nil)
        #expect(finalPlan?.textMood == .angry)
        #expect(finalPlan?.performanceStyle == .stormy)
        #expect(finalPlan?.sustainPedalEngaged == false)
        #expect(engine.performanceDescription.contains("Felt Bloom"))
        #expect(engine.performanceDescription.contains("Stormy"))
    }

    @MainActor
    @Test func burstKeepsItsLockedMoodUntilPause() {
        var engine = KeyboardMusicEngine(instrument: .piano)
        let sequence: [(KeyboardSymbol, TimeInterval)] = [
            (.letter("l"), 0.0),
            (.letter("o"), 0.2),
            (.letter("v"), 0.4),
            (.letter("e"), 0.6),
            (.space, 0.8),
            (.letter("f"), 1.0),
            (.letter("u"), 1.2),
            (.letter("c"), 1.4),
            (.letter("k"), 1.6)
        ]

        let finalPlan = sequence.reduce(into: SoundTriggerPlan?.none) { currentPlan, step in
            currentPlan = engine.plan(for: KeyboardInput(
                symbol: step.0,
                keyCode: 0,
                source: .localApp,
                timestamp: Date(timeIntervalSinceReferenceDate: step.1)
            ))
        }

        #expect(finalPlan != nil)
        #expect(finalPlan?.textMood == .joyful)
        #expect(finalPlan?.performanceStyle == .bright)
    }

    @MainActor
    @Test func pauseStartsANewPerformanceBurst() {
        var engine = KeyboardMusicEngine(instrument: .piano)

        let firstBurst: [(KeyboardSymbol, TimeInterval)] = [
            (.letter("l"), 0.0),
            (.letter("o"), 0.2),
            (.letter("v"), 0.4),
            (.letter("e"), 0.6)
        ]
        let secondBurst: [(KeyboardSymbol, TimeInterval)] = [
            (.letter("f"), 4.2),
            (.letter("u"), 4.4),
            (.letter("c"), 4.6),
            (.letter("k"), 4.8)
        ]

        _ = firstBurst.reduce(into: SoundTriggerPlan?.none) { currentPlan, step in
            currentPlan = engine.plan(for: KeyboardInput(
                symbol: step.0,
                keyCode: 0,
                source: .localApp,
                timestamp: Date(timeIntervalSinceReferenceDate: step.1)
            ))
        }
        let finalPlan = secondBurst.reduce(into: SoundTriggerPlan?.none) { currentPlan, step in
            currentPlan = engine.plan(for: KeyboardInput(
                symbol: step.0,
                keyCode: 0,
                source: .localApp,
                timestamp: Date(timeIntervalSinceReferenceDate: step.1)
            ))
        }

        #expect(finalPlan != nil)
        #expect(finalPlan?.textMood == .angry)
        #expect(finalPlan?.performanceStyle == .stormy)
    }

    @MainActor
    @Test func punctuationReleasesPhrasePedal() {
        var engine = KeyboardMusicEngine(instrument: .piano)

        let letterPlan = engine.plan(for: KeyboardInput(
            symbol: .letter("h"),
            keyCode: 4,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
        ))
        let punctuationPlan = engine.plan(for: KeyboardInput(
            symbol: .punctuation("."),
            keyCode: 47,
            source: .localApp,
            timestamp: Date(timeIntervalSinceReferenceDate: 0.8)
        ))

        #expect(letterPlan.sustainPedalEngaged)
        #expect(!punctuationPlan.sustainPedalEngaged)
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
    @Test func dashboardTrackerEstimatesWordsPerMinuteFromTypedCharacters() {
        var tracker = TypingDashboardTracker()

        _ = tracker.register(symbol: .letter("h"), at: Date(timeIntervalSinceReferenceDate: 0))
        _ = tracker.register(symbol: .letter("e"), at: Date(timeIntervalSinceReferenceDate: 0.5))
        _ = tracker.register(symbol: .letter("l"), at: Date(timeIntervalSinceReferenceDate: 1.0))
        _ = tracker.register(symbol: .letter("l"), at: Date(timeIntervalSinceReferenceDate: 1.5))
        let snapshot = tracker.register(symbol: .letter("o"), at: Date(timeIntervalSinceReferenceDate: 2.0))

        #expect(snapshot.wordsPerMinute == 20)
    }

    @MainActor
    @Test func dashboardTrackerIgnoresModifiersAndTracksSessionHotKeys() {
        var tracker = TypingDashboardTracker()

        _ = tracker.register(symbol: .modifier(.shift), at: Date(timeIntervalSinceReferenceDate: 0))
        _ = tracker.register(symbol: .letter("a"), at: Date(timeIntervalSinceReferenceDate: 0.2))
        _ = tracker.register(symbol: .modifier(.shift), at: Date(timeIntervalSinceReferenceDate: 0.4))
        _ = tracker.register(symbol: .letter("a"), at: Date(timeIntervalSinceReferenceDate: 0.6))
        let snapshot = tracker.register(symbol: .letter("s"), at: Date(timeIntervalSinceReferenceDate: 0.8))

        #expect(snapshot.wordsPerMinute == 12)
        #expect(snapshot.topKeys.first?.label == "A")
        #expect(snapshot.topKeys.first?.count == 2)
        #expect(snapshot.topKeys.contains(where: { $0.label == "S" && $0.count == 1 }))
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
