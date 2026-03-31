//
//  MoonlightPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum MoonlightPianoProfile {
    static let profile = PianoSoundProfile(
        id: "moonlight",
        displayName: "Moonlight",
        summary: "Dark piano with a longer tail.",
        soundPrefix: "piano-moonlight",
        programNumber: 2,
        masterGain: -1.1,
        registerMap: PianoRegisterMap(
            bass: ["A2", "C3", "D3", "E3", "G3"],
            low: ["A3", "C4", "D4", "E4", "G4"],
            middle: ["C4", "D4", "E4", "G4", "A4", "C5"],
            upper: ["E4", "G4", "A4", "C5", "D5", "E5"],
            high: ["A4", "C5", "D5", "E5", "G5", "A5"]
        ),
        accentPalette: ["A3", "C4", "D4", "E4", "G4", "A4", "C5"],
        supportPalette: ["A3", "E4", "G4", "A4", "C5"],
        tensionNote: "B4",
        texturePalette: ["E5", "G5", "A5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 190, bandwidth: 0.9, gain: 1.0),
                EQBandConfiguration(filterType: .parametric, frequency: 350, bandwidth: 1.02, gain: -1.6),
                EQBandConfiguration(filterType: .parametric, frequency: 3_000, bandwidth: 0.96, gain: -1.0)
            ],
            reverbPreset: .largeHall,
            reverbMix: 27,
            delayTime: 0.03,
            delayFeedback: 1.9,
            delayLowPassCutoff: 4_300,
            delayMix: 2.9,
            spaceVolume: 0.93,
            outputVolume: 0.85
        ),
        baseVelocityScale: 0.94,
        melodyDurationScale: 1.16,
        pulseDurationScale: 0.95,
        cadenceDurationScale: 1.18,
        anchorBaseMidi: 60,
        registerBias: -1
    )
}
