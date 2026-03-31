//
//  CustomPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum CustomPianoPitch: String, CaseIterable, Identifiable, CustomStringConvertible {
    case low
    case balanced
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:
            "Low"
        case .balanced:
            "Balanced"
        case .high:
            "High"
        }
    }

    var summary: String {
        switch self {
        case .low:
            "Lower range."
        case .balanced:
            "Middle range."
        case .high:
            "Higher range."
        }
    }

    var description: String { displayName }

    var semitoneOffset: Int {
        switch self {
        case .low:
            -4
        case .balanced:
            0
        case .high:
            4
        }
    }

    var registerBiasDelta: Int {
        switch self {
        case .low:
            -2
        case .balanced:
            0
        case .high:
            2
        }
    }
}

enum CustomPianoTone: String, CaseIterable, Identifiable, CustomStringConvertible {
    case soft
    case warm
    case bright

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soft:
            "Soft"
        case .warm:
            "Warm"
        case .bright:
            "Bright"
        }
    }

    var summary: String {
        switch self {
        case .soft:
            "Softer attack."
        case .warm:
            "Balanced body."
        case .bright:
            "Brighter tone."
        }
    }

    var description: String { displayName }

    var masterGainDelta: Float {
        switch self {
        case .soft:
            -0.4
        case .warm:
            0
        case .bright:
            0.35
        }
    }

    var bodyGainDelta: Float {
        switch self {
        case .soft:
            0.8
        case .warm:
            0.2
        case .bright:
            -0.3
        }
    }

    var presenceGainDelta: Float {
        switch self {
        case .soft:
            -1.2
        case .warm:
            -0.1
        case .bright:
            1.6
        }
    }

    var reverbMixDelta: Float {
        switch self {
        case .soft:
            2.2
        case .warm:
            0.6
        case .bright:
            -1.4
        }
    }

    var outputDelta: Float {
        switch self {
        case .soft:
            -0.01
        case .warm:
            0
        case .bright:
            0.015
        }
    }

    var velocityScale: Double {
        switch self {
        case .soft:
            0.97
        case .warm:
            1
        case .bright:
            1.03
        }
    }
}

enum CustomPianoVibe: String, CaseIterable, Identifiable, CustomStringConvertible {
    case cozy
    case playful
    case lounge
    case dreamy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cozy:
            "Cozy"
        case .playful:
            "Playful"
        case .lounge:
            "Lounge"
        case .dreamy:
            "Dreamy"
        }
    }

    var summary: String {
        switch self {
        case .cozy:
            "Soft and close."
        case .playful:
            "Light and open."
        case .lounge:
            "Dry and warm."
        case .dreamy:
            "Dark and airy."
        }
    }

    var description: String { displayName }

    var baseProfile: PianoSoundProfile {
        switch self {
        case .cozy:
            WarmFeltPianoProfile.profile
        case .playful:
            ConcertHallPianoProfile.profile
        case .lounge:
            AmberUprightPianoProfile.profile
        case .dreamy:
            MoonlightPianoProfile.profile
        }
    }
}

struct CustomPianoSettings: Equatable {
    var pitch: CustomPianoPitch = .balanced
    var tone: CustomPianoTone = .warm
    var vibe: CustomPianoVibe = .cozy

    static let `default` = CustomPianoSettings()

    var summary: String {
        "\(tone.displayName) tone, \(vibe.displayName.lowercased()) feel, \(pitch.displayName.lowercased()) range."
    }
}

enum CustomPianoProfileBuilder {
    static let profileID = "custom-mix"

    static func makeProfile(from settings: CustomPianoSettings) -> PianoSoundProfile {
        let base = settings.vibe.baseProfile
        let effect = adjustedEffectConfiguration(base.effectConfiguration, tone: settings.tone)

        return PianoSoundProfile(
            id: profileID,
            displayName: "Custom Mix",
            summary: settings.summary,
            soundPrefix: "piano-custom-mix",
            programNumber: base.programNumber,
            masterGain: base.masterGain + settings.tone.masterGainDelta,
            registerMap: transposedRegisterMap(base.registerMap, by: settings.pitch.semitoneOffset),
            accentPalette: transpose(base.accentPalette, by: settings.pitch.semitoneOffset),
            supportPalette: transpose(base.supportPalette, by: settings.pitch.semitoneOffset),
            tensionNote: transpose(base.tensionNote, by: settings.pitch.semitoneOffset),
            texturePalette: transpose(base.texturePalette, by: settings.pitch.semitoneOffset),
            effectConfiguration: effect,
            baseVelocityScale: base.baseVelocityScale * settings.tone.velocityScale,
            melodyDurationScale: base.melodyDurationScale,
            pulseDurationScale: base.pulseDurationScale,
            cadenceDurationScale: base.cadenceDurationScale,
            anchorBaseMidi: base.anchorBaseMidi + settings.pitch.semitoneOffset,
            registerBias: base.registerBias + settings.pitch.registerBiasDelta
        )
    }

    private static func adjustedEffectConfiguration(
        _ base: InstrumentEffectConfiguration,
        tone: CustomPianoTone
    ) -> InstrumentEffectConfiguration {
        let bodyBand = adjustBand(base.eqBands, at: 0, gainDelta: tone.bodyGainDelta)
        let midBand = adjustBand(bodyBand, at: 1, gainDelta: tone.bodyGainDelta * -0.35)
        let presenceBand = adjustBand(midBand, at: 2, gainDelta: tone.presenceGainDelta)

        return InstrumentEffectConfiguration(
            eqBands: presenceBand,
            reverbPreset: base.reverbPreset,
            reverbMix: max(6, base.reverbMix + tone.reverbMixDelta),
            delayTime: base.delayTime,
            delayFeedback: base.delayFeedback,
            delayLowPassCutoff: base.delayLowPassCutoff,
            delayMix: base.delayMix,
            spaceVolume: min(max(base.spaceVolume, 0.7), 1),
            outputVolume: min(max(base.outputVolume + tone.outputDelta, 0.6), 1)
        )
    }

    private static func adjustBand(
        _ bands: [EQBandConfiguration],
        at index: Int,
        gainDelta: Float
    ) -> [EQBandConfiguration] {
        guard bands.indices.contains(index) else { return bands }

        var updated = bands
        let band = bands[index]
        updated[index] = EQBandConfiguration(
            filterType: band.filterType,
            frequency: band.frequency,
            bandwidth: band.bandwidth,
            gain: band.gain + gainDelta
        )
        return updated
    }

    private static func transposedRegisterMap(_ registerMap: PianoRegisterMap, by semitones: Int) -> PianoRegisterMap {
        PianoRegisterMap(
            bass: transpose(registerMap.bass, by: semitones),
            low: transpose(registerMap.low, by: semitones),
            middle: transpose(registerMap.middle, by: semitones),
            upper: transpose(registerMap.upper, by: semitones),
            high: transpose(registerMap.high, by: semitones)
        )
    }

    private static func transpose(_ notes: [String], by semitones: Int) -> [String] {
        notes.map { transpose($0, by: semitones) }
    }

    private static func transpose(_ note: String, by semitones: Int) -> String {
        guard let midi = KeyboardNoteFrequency.midiNote(for: note) else {
            return note
        }

        return noteLabel(for: Int(midi) + semitones)
    }

    private static func noteLabel(for midi: Int) -> String {
        let clamped = min(max(midi, 24), 96)
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteName = noteNames[((clamped % 12) + 12) % 12]
        let octave = (clamped / 12) - 1
        return "\(noteName)\(octave)"
    }
}
