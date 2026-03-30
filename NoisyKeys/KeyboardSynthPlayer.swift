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
    private let engine = AVAudioEngine()
    private let spaceMixer = AVAudioMixerNode()
    private let reverb = AVAudioUnitReverb()
    private let delay = AVAudioUnitDelay()
    private let soundBankURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

    private var pianoVoices: [SamplerVoice] = []
    private var loFiVoices: [SamplerVoice] = []
    private var nextPianoVoiceIndex = 0
    private var nextLoFiVoiceIndex = 0
    private var currentEffectProfile: KeyboardInstrument?

    init() {
        engine.attach(spaceMixer)
        engine.attach(reverb)
        engine.attach(delay)

        configureVoicePool()

        engine.connect(spaceMixer, to: reverb, format: nil)
        engine.connect(reverb, to: delay, format: nil)
        engine.connect(delay, to: engine.mainMixerNode, format: nil)

        spaceMixer.outputVolume = 0.94
        engine.mainMixerNode.outputVolume = 0.88

        configureEffects(for: .piano)
        engine.prepare()
        startEngineIfNeeded()
    }

    func play(_ plan: SoundTriggerPlan) {
        startEngineIfNeeded()
        configureEffects(for: plan.instrument)

        guard let noteNumber = KeyboardNoteFrequency.midiNote(for: plan.noteLabel) else {
            return
        }

        let profile = InstrumentPlaybackProfile(plan.instrument)
        let scaledVelocity = min(max(plan.velocity * profile.roleVelocityScale(for: plan.role), 0.16), 1)
        let midiVelocity = UInt8(max(1, min(Int((scaledVelocity * 127).rounded()), 127)))
        let voice = nextVoice(for: plan.instrument)

        voice.play(
            noteNumber: noteNumber,
            velocity: midiVelocity,
            duration: profile.duration(for: plan.role)
        )
    }

    private func configureVoicePool() {
        pianoVoices = makeVoices(for: .piano, count: 12)
        loFiVoices = makeVoices(for: .loFiKeys, count: 12)
    }

    private func makeVoices(for instrument: KeyboardInstrument, count: Int) -> [SamplerVoice] {
        let profile = InstrumentPlaybackProfile(instrument)

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

    private func nextVoice(for instrument: KeyboardInstrument) -> SamplerVoice {
        switch instrument {
        case .piano:
            if pianoVoices.isEmpty {
                pianoVoices = makeVoices(for: .piano, count: 8)
            }
            if pianoVoices.isEmpty {
                let fallbackVoice = SamplerVoice()
                engine.attach(fallbackVoice.sampler)
                engine.connect(fallbackVoice.sampler, to: spaceMixer, format: nil)
                pianoVoices = [fallbackVoice]
            }
            let index = nextPianoVoiceIndex % max(pianoVoices.count, 1)
            nextPianoVoiceIndex = (nextPianoVoiceIndex + 1) % max(pianoVoices.count, 1)
            return pianoVoices[index]
        case .loFiKeys:
            if loFiVoices.isEmpty {
                loFiVoices = makeVoices(for: .loFiKeys, count: 8)
            }
            if loFiVoices.isEmpty {
                let fallbackVoice = SamplerVoice()
                engine.attach(fallbackVoice.sampler)
                engine.connect(fallbackVoice.sampler, to: spaceMixer, format: nil)
                loFiVoices = [fallbackVoice]
            }
            let index = nextLoFiVoiceIndex % max(loFiVoices.count, 1)
            nextLoFiVoiceIndex = (nextLoFiVoiceIndex + 1) % max(loFiVoices.count, 1)
            return loFiVoices[index]
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
        } catch {
            NSLog("NoisyKeys failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func configureEffects(for instrument: KeyboardInstrument) {
        guard currentEffectProfile != instrument else { return }

        switch instrument {
        case .piano:
            reverb.loadFactoryPreset(.smallRoom)
            reverb.wetDryMix = 11
            delay.delayTime = 0
            delay.feedback = 0
            delay.lowPassCutoff = 12_000
            delay.wetDryMix = 0
        case .loFiKeys:
            reverb.loadFactoryPreset(.mediumChamber)
            reverb.wetDryMix = 18
            delay.delayTime = 0.09
            delay.feedback = 7
            delay.lowPassCutoff = 4_200
            delay.wetDryMix = 10
        }

        currentEffectProfile = instrument
    }
}

private final class SamplerVoice {
    let sampler = AVAudioUnitSampler()

    private let stateQueue = DispatchQueue(label: "NoisyKeys.SamplerVoice")
    private var playbackToken: UInt64 = 0
    private var currentNote: UInt8?

    func load(soundBankURL: URL, program: UInt8, masterGain: Float) throws {
        try sampler.loadSoundBankInstrument(
            at: soundBankURL,
            program: program,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: 0
        )
        sampler.masterGain = masterGain
    }

    func play(noteNumber: UInt8, velocity: UInt8, duration: TimeInterval) {
        stateQueue.async {
            self.playbackToken &+= 1
            let token = self.playbackToken

            if let currentNote = self.currentNote {
                self.sampler.stopNote(currentNote, onChannel: 0)
            }

            self.currentNote = noteNumber
            self.sampler.startNote(noteNumber, withVelocity: velocity, onChannel: 0)

            self.stateQueue.asyncAfter(deadline: .now() + duration) {
                guard token == self.playbackToken, self.currentNote == noteNumber else { return }
                self.sampler.stopNote(noteNumber, onChannel: 0)
                self.currentNote = nil
            }
        }
    }
}

private struct InstrumentPlaybackProfile {
    let instrument: KeyboardInstrument

    init(_ instrument: KeyboardInstrument) {
        self.instrument = instrument
    }

    var programNumber: UInt8 {
        switch instrument {
        case .piano:
            0
        case .loFiKeys:
            4
        }
    }

    var masterGain: Float {
        switch instrument {
        case .piano:
            0
        case .loFiKeys:
            -2
        }
    }

    func duration(for role: KeyboardSoundRole) -> TimeInterval {
        switch instrument {
        case .piano:
            switch role {
            case .melody:
                0.44
            case .pulse:
                0.28
            case .cadence:
                0.62
            case .tension:
                0.26
            case .texture:
                0.22
            case .accent:
                0.34
            case .navigation:
                0.24
            }
        case .loFiKeys:
            switch role {
            case .melody:
                0.62
            case .pulse:
                0.34
            case .cadence:
                0.82
            case .tension:
                0.38
            case .texture:
                0.32
            case .accent:
                0.42
            case .navigation:
                0.3
            }
        }
    }

    func roleVelocityScale(for role: KeyboardSoundRole) -> Double {
        switch instrument {
        case .piano:
            switch role {
            case .melody:
                0.95
            case .pulse:
                0.82
            case .cadence:
                1
            case .tension:
                0.74
            case .texture:
                0.68
            case .accent:
                0.9
            case .navigation:
                0.66
            }
        case .loFiKeys:
            switch role {
            case .melody:
                0.88
            case .pulse:
                0.8
            case .cadence:
                0.94
            case .tension:
                0.72
            case .texture:
                0.68
            case .accent:
                0.84
            case .navigation:
                0.64
            }
        }
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
