//
//  KeyboardSynthPlayer.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/30/26.
//

import AudioToolbox
import AVFoundation
import Foundation

final class KeyboardSynthPlayer {
    private let pianoVoiceCount = 40
    private let loFiVoiceCount = 32
    private let engine = AVAudioEngine()
    private let spaceMixer = AVAudioMixerNode()
    private let toneEQ = AVAudioUnitEQ(numberOfBands: 3)
    private let reverb = AVAudioUnitReverb()
    private let delay = AVAudioUnitDelay()
    private let soundBankURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

    private var pianoVoices: [SamplerVoice] = []
    private var loFiVoices: [SamplerVoice] = []
    private var nextPianoVoiceIndex = 0
    private var nextLoFiVoiceIndex = 0
    private var pianoLoadedProfileID: String?
    private var loFiLoadedProfileID: String?
    private var currentEffectProfile: EffectProfileKey?
    private var pianoPedalEngaged = false
    private var loFiPedalEngaged = false

    init() {
        engine.attach(spaceMixer)
        engine.attach(toneEQ)
        engine.attach(reverb)
        engine.attach(delay)

        configureVoicePool()

        engine.connect(spaceMixer, to: toneEQ, format: nil)
        engine.connect(toneEQ, to: reverb, format: nil)
        engine.connect(reverb, to: delay, format: nil)
        engine.connect(delay, to: engine.mainMixerNode, format: nil)

        spaceMixer.outputVolume = 0.94
        engine.mainMixerNode.outputVolume = 0.88

        configureEffects(for: SoundTriggerPlan(
            instrument: .piano,
            profile: PianoProfileCatalog.defaultProfile.snapshot,
            role: .melody,
            soundID: "preview",
            noteLabel: "C4",
            noteFamilyName: "Preview",
            keyLabel: "Preview",
            source: .localApp,
            tempo: .idle,
            textMood: .neutral,
            performanceStyle: .warm,
            sustainPedalEngaged: false,
            velocity: 0.72,
            learnedRank: nil
        ))
        engine.prepare()
        startEngineIfNeeded()
    }

    func play(_ plan: SoundTriggerPlan) {
        startEngineIfNeeded()
        configureEffects(for: plan)
        applyPhrasePedal(for: plan)

        guard let noteNumber = KeyboardNoteFrequency.midiNote(for: plan.noteLabel) else {
            return
        }

        let profile = InstrumentPlaybackProfile(plan.instrument, performanceStyle: plan.performanceStyle)
        let scaledVelocity = min(max(plan.velocity * profile.roleVelocityScale(for: plan.role, profile: plan.profile), 0.16), 1)
        let midiVelocity = UInt8(max(1, min(Int((scaledVelocity * 127).rounded()), 127)))
        let duration = profile.duration(for: plan.role, tempo: plan.tempo, profile: plan.profile)
        let voice = nextVoice(
            for: plan.instrument,
            profile: plan.profile,
            noteNumber: noteNumber,
            reservingFor: duration,
            preferMatchingActiveNote: shouldCollapseDuplicateNotes(for: plan)
        )

        voice.play(
            noteNumber: noteNumber,
            velocity: midiVelocity,
            duration: duration
        )
    }

    func resetPerformanceState() {
        setPedal(false, for: .piano)
        setPedal(false, for: .loFiKeys)
    }

    private func configureVoicePool() {
        pianoVoices = makeVoices(for: PianoProfileCatalog.defaultProfile.snapshot, instrument: .piano, count: pianoVoiceCount)
        loFiVoices = makeVoices(for: LoFiProfileCatalog.defaultProfile.snapshot, instrument: .loFiKeys, count: loFiVoiceCount)
        pianoLoadedProfileID = PianoProfileCatalog.defaultProfile.id
        loFiLoadedProfileID = LoFiProfileCatalog.defaultProfile.id
    }

    private func makeVoices(for profile: InstrumentProfileSnapshot, instrument: KeyboardInstrument, count: Int) -> [SamplerVoice] {
        return (0..<count).compactMap { _ in
            let voice = SamplerVoice()
            engine.attach(voice.sampler)
            engine.connect(voice.sampler, to: spaceMixer, format: nil)

            do {
                try voice.load(
                    soundBankURL: soundBankURL,
                    program: profile.programNumber,
                    masterGain: profile.masterGain
                )
                return voice
            } catch {
                NSLog("NoisyKeys failed to load \(instrument.displayName) sampler voice: \(error.localizedDescription)")
                return nil
            }
        }
    }

    private func nextVoice(
        for instrument: KeyboardInstrument,
        profile: InstrumentProfileSnapshot,
        noteNumber: UInt8,
        reservingFor duration: TimeInterval,
        preferMatchingActiveNote: Bool
    ) -> SamplerVoice {
        let now = Date()
        let reservedUntil = now.addingTimeInterval(duration)
        ensureVoicePoolLoaded(for: instrument, profile: profile)

        switch instrument {
        case .piano:
            if pianoVoices.isEmpty {
                let fallbackVoice = SamplerVoice()
                engine.attach(fallbackVoice.sampler)
                engine.connect(fallbackVoice.sampler, to: spaceMixer, format: nil)
                pianoVoices = [fallbackVoice]
            }
            let voice = selectVoice(
                from: pianoVoices,
                startingAt: nextPianoVoiceIndex,
                noteNumber: noteNumber,
                preferMatchingActiveNote: preferMatchingActiveNote,
                now: now
            )
            let currentIndex = pianoVoices.firstIndex(where: { $0 === voice }) ?? 0
            nextPianoVoiceIndex = (currentIndex + 1) % max(pianoVoices.count, 1)
            voice.reserve(until: reservedUntil)
            return voice
        case .loFiKeys:
            if loFiVoices.isEmpty {
                let fallbackVoice = SamplerVoice()
                engine.attach(fallbackVoice.sampler)
                engine.connect(fallbackVoice.sampler, to: spaceMixer, format: nil)
                loFiVoices = [fallbackVoice]
            }
            let voice = selectVoice(
                from: loFiVoices,
                startingAt: nextLoFiVoiceIndex,
                noteNumber: noteNumber,
                preferMatchingActiveNote: preferMatchingActiveNote,
                now: now
            )
            let currentIndex = loFiVoices.firstIndex(where: { $0 === voice }) ?? 0
            nextLoFiVoiceIndex = (currentIndex + 1) % max(loFiVoices.count, 1)
            voice.reserve(until: reservedUntil)
            return voice
        }
    }

    private func ensureVoicePoolLoaded(for instrument: KeyboardInstrument, profile: InstrumentProfileSnapshot) {
        switch instrument {
        case .piano:
            guard pianoLoadedProfileID != profile.id || pianoVoices.isEmpty else { return }
            setPedal(false, for: .piano)
            pianoVoices = reloadVoices(existing: pianoVoices, profile: profile, instrument: .piano)
            nextPianoVoiceIndex = 0
            pianoLoadedProfileID = profile.id
        case .loFiKeys:
            guard loFiLoadedProfileID != profile.id || loFiVoices.isEmpty else { return }
            setPedal(false, for: .loFiKeys)
            loFiVoices = reloadVoices(existing: loFiVoices, profile: profile, instrument: .loFiKeys)
            nextLoFiVoiceIndex = 0
            loFiLoadedProfileID = profile.id
        }
    }

    private func reloadVoices(
        existing voices: [SamplerVoice],
        profile: InstrumentProfileSnapshot,
        instrument: KeyboardInstrument
    ) -> [SamplerVoice] {
        for voice in voices {
            voice.stopImmediately()
            engine.detach(voice.sampler)
        }

        return makeVoices(for: profile, instrument: instrument, count: max(voices.count, 12))
    }

    private func selectVoice(
        from voices: [SamplerVoice],
        startingAt startIndex: Int,
        noteNumber: UInt8,
        preferMatchingActiveNote: Bool,
        now: Date
    ) -> SamplerVoice {
        let rotated = rotatedVoices(from: voices, startingAt: startIndex)
        if preferMatchingActiveNote,
           let matchingVoice = rotated.first(where: { $0.isPlaying(noteNumber: noteNumber, at: now) }) {
            return matchingVoice
        }
        if let availableVoice = rotated.first(where: { $0.isAvailable(at: now) }) {
            return availableVoice
        }

        return rotated.min { lhs, rhs in
            lhs.reservedUntil < rhs.reservedUntil
        } ?? voices[0]
    }

    private func rotatedVoices(from voices: [SamplerVoice], startingAt startIndex: Int) -> [SamplerVoice] {
        guard !voices.isEmpty else { return [] }

        let index = startIndex % voices.count
        return Array(voices[index...] + voices[..<index])
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
        } catch {
            NSLog("NoisyKeys failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func applyPhrasePedal(for plan: SoundTriggerPlan) {
        if plan.instrument != .piano {
            setPedal(false, for: .piano)
            return
        }

        setPedal(plan.sustainPedalEngaged, for: .piano)
    }

    private func setPedal(_ isEngaged: Bool, for instrument: KeyboardInstrument) {
        switch instrument {
        case .piano:
            guard pianoPedalEngaged != isEngaged else { return }
            pianoPedalEngaged = isEngaged
            sendController(64, value: isEngaged ? 127 : 0, to: pianoVoices)
        case .loFiKeys:
            guard loFiPedalEngaged != isEngaged else { return }
            loFiPedalEngaged = isEngaged
            sendController(64, value: isEngaged ? 127 : 0, to: loFiVoices)
        }
    }

    private func sendController(_ controller: UInt8, value: UInt8, to voices: [SamplerVoice]) {
        for voice in voices {
            voice.sampler.sendController(controller, withValue: value, onChannel: 0)
        }
    }

    private func shouldCollapseDuplicateNotes(for plan: SoundTriggerPlan) -> Bool {
        false
    }

    private func configureEffects(for plan: SoundTriggerPlan) {
        let effectProfile = EffectProfileKey(
            instrument: plan.instrument,
            profileID: plan.profile.id
        )
        guard currentEffectProfile != effectProfile else { return }

        switch plan.instrument {
        case .piano:
            configurePianoEffects(for: plan.profile)
        case .loFiKeys:
            configureLoFiEffects(for: plan.profile)
        }

        currentEffectProfile = effectProfile
    }

    private func configureEQ(_ configurations: [EQBandConfiguration]) {
        for (band, configuration) in zip(toneEQ.bands, configurations) {
            band.filterType = configuration.filterType
            band.frequency = configuration.frequency
            band.bandwidth = configuration.bandwidth
            band.gain = configuration.gain
            band.bypass = false
        }
    }

    private func configurePianoEffects(for profile: InstrumentProfileSnapshot) {
        applyEffectConfiguration(PianoPlaybackProfile.effectConfiguration(for: profile))
    }

    private func configureLoFiEffects(for profile: InstrumentProfileSnapshot) {
        applyEffectConfiguration(profile.effectConfiguration)
    }

    private func applyEffectConfiguration(_ configuration: InstrumentEffectConfiguration) {
        configureEQ(configuration.eqBands)
        reverb.loadFactoryPreset(configuration.reverbPreset)
        reverb.wetDryMix = configuration.reverbMix
        delay.delayTime = configuration.delayTime
        delay.feedback = configuration.delayFeedback
        delay.lowPassCutoff = configuration.delayLowPassCutoff
        delay.wetDryMix = configuration.delayMix
        spaceMixer.outputVolume = configuration.spaceVolume
        engine.mainMixerNode.outputVolume = configuration.outputVolume
    }
}

private struct EffectProfileKey: Equatable {
    let instrument: KeyboardInstrument
    let profileID: String
}

private final class SamplerVoice {
    let sampler = AVAudioUnitSampler()

    private let stateQueue = DispatchQueue(label: "NoisyKeys.SamplerVoice")
    private var reservedUntilStorage = Date.distantPast
    private var currentNoteNumberStorage: UInt8?

    func load(soundBankURL: URL, program: UInt8, masterGain: Float) throws {
        try sampler.loadSoundBankInstrument(
            at: soundBankURL,
            program: program,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: 0
        )
        sampler.masterGain = masterGain
    }

    var reservedUntil: Date {
        stateQueue.sync { reservedUntilStorage }
    }

    func isAvailable(at date: Date) -> Bool {
        reservedUntil <= date
    }

    func isPlaying(noteNumber: UInt8, at date: Date) -> Bool {
        stateQueue.sync {
            currentNoteNumberStorage == noteNumber && reservedUntilStorage > date
        }
    }

    func reserve(until date: Date) {
        stateQueue.sync {
            reservedUntilStorage = max(reservedUntilStorage, date)
        }
    }

    func stopImmediately() {
        stateQueue.sync {
            if let currentNoteNumber = currentNoteNumberStorage {
                sampler.stopNote(currentNoteNumber, onChannel: 0)
            }
            currentNoteNumberStorage = nil
            reservedUntilStorage = .distantPast
        }
    }

    func play(noteNumber: UInt8, velocity: UInt8, duration: TimeInterval) {
        stateQueue.async {
            if let currentNoteNumber = self.currentNoteNumberStorage {
                self.sampler.stopNote(currentNoteNumber, onChannel: 0)
            }
            self.currentNoteNumberStorage = noteNumber
            self.sampler.startNote(noteNumber, withVelocity: velocity, onChannel: 0)

            self.stateQueue.asyncAfter(deadline: .now() + duration) {
                guard self.currentNoteNumberStorage == noteNumber else { return }
                self.sampler.stopNote(noteNumber, onChannel: 0)
                self.currentNoteNumberStorage = nil
            }
        }
    }
}

private struct InstrumentPlaybackProfile {
    let instrument: KeyboardInstrument
    let performanceStyle: KeyboardPerformanceStyle

    init(_ instrument: KeyboardInstrument, performanceStyle: KeyboardPerformanceStyle = .warm) {
        self.instrument = instrument
        self.performanceStyle = performanceStyle
    }

    func duration(for role: KeyboardSoundRole, tempo: TypingTempoSnapshot, profile: InstrumentProfileSnapshot) -> TimeInterval {
        let baseDuration: TimeInterval

        switch instrument {
        case .piano:
            return PianoPlaybackProfile.duration(
                for: role,
                tempo: tempo,
                performanceStyle: performanceStyle,
                profile: profile
            )
        case .loFiKeys:
            switch role {
            case .melody:
                baseDuration = 0.92
            case .pulse:
                baseDuration = 0.34
            case .cadence:
                baseDuration = 1.14
            case .tension:
                baseDuration = 0.6
            case .texture:
                baseDuration = 0.56
            case .accent:
                baseDuration = 0.76
            case .navigation:
                baseDuration = 0.52
            }
        }

        let profileScale: Double
        switch role {
        case .melody:
            profileScale = profile.melodyDurationScale
        case .pulse:
            profileScale = profile.pulseDurationScale
        case .cadence:
            profileScale = profile.cadenceDurationScale
        case .tension, .texture, .accent, .navigation:
            profileScale = 1
        }

        return baseDuration * profileScale * durationMultiplier(for: role, tempo: tempo)
    }

    func roleVelocityScale(for role: KeyboardSoundRole, profile: InstrumentProfileSnapshot) -> Double {
        switch instrument {
        case .piano:
            return PianoPlaybackProfile.roleVelocityScale(
                for: role,
                performanceStyle: performanceStyle,
                profile: profile
            )
        case .loFiKeys:
            return profile.baseVelocityScale
        }
    }

    private func durationMultiplier(for role: KeyboardSoundRole, tempo: TypingTempoSnapshot) -> Double {
        let phraseMultiplier: Double
        switch instrument {
        case .piano:
            switch tempo.intensity {
            case .idle, .relaxed:
                phraseMultiplier = 1.18
            case .steady:
                phraseMultiplier = 1.04
            case .energetic:
                phraseMultiplier = 0.98
            case .frantic:
                phraseMultiplier = 0.92
            }
        case .loFiKeys:
            switch tempo.intensity {
            case .idle, .relaxed:
                phraseMultiplier = 1.16
            case .steady:
                phraseMultiplier = 1.12
            case .energetic:
                phraseMultiplier = 1.24
            case .frantic:
                phraseMultiplier = 1.34
            }
        }

        let roleBias: Double
        switch role {
        case .melody:
            roleBias = 1.08
        case .pulse:
            roleBias = 0.76
        case .cadence:
            roleBias = 1.16
        case .tension:
            roleBias = 1
        case .texture:
            roleBias = 0.98
        case .accent:
            roleBias = 1.02
        case .navigation:
            roleBias = 1
        }

        return phraseMultiplier * roleBias
    }
}

enum KeyboardNoteFrequency {
    static func midiNote(for noteLabel: String) -> UInt8? {
        guard let midiValue = midiValue(for: noteLabel) else {
            return nil
        }

        return UInt8(clamping: midiValue)
    }

    static func hz(for noteLabel: String) -> Double? {
        guard let midiValue = midiValue(for: noteLabel) else {
            return nil
        }

        return 440 * pow(2, Double(midiValue - 69) / 12)
    }

    private static func midiValue(for noteLabel: String) -> Int? {
        let trimmed = noteLabel.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return nil }

        var noteName = trimmed
        var octaveDigits = ""

        while let last = noteName.last, last.isNumber {
            octaveDigits.insert(last, at: octaveDigits.startIndex)
            noteName.removeLast()
        }

        guard let octave = Int(octaveDigits),
              let semitone = semitoneMap[noteName] else {
            return nil
        }

        return ((octave + 1) * 12) + semitone
    }

    private static let semitoneMap: [String: Int] = [
        "C": 0,
        "C#": 1,
        "DB": 1,
        "D": 2,
        "D#": 3,
        "EB": 3,
        "E": 4,
        "F": 5,
        "F#": 6,
        "GB": 6,
        "G": 7,
        "G#": 8,
        "AB": 8,
        "A": 9,
        "A#": 10,
        "BB": 10,
        "B": 11
    ]
}
