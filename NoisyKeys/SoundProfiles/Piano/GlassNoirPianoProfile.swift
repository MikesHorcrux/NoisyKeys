//
//  GlassNoirPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum GlassNoirPianoProfile {
    static let profile = PianoSoundProfile(
        id: "glass-noir",
        displayName: "Glass Noir",
        summary: "Sharper, colder piano for tense noir phrases.",
        soundPrefix: "piano-glass-noir",
        programNumber: 1,
        masterGain: -0.5,
        registerMap: PianoRegisterMap(
            bass: ["B2", "D3", "E3", "G3", "A3"],
            low: ["D3", "E3", "G3", "A3", "C4"],
            middle: ["E3", "G3", "A3", "C4", "D4", "E4"],
            upper: ["A3", "C4", "D4", "E4", "G4", "A4"],
            high: ["D4", "E4", "G4", "A4", "C5", "D5"]
        ),
        accentPalette: ["D3", "E3", "G3", "A3", "C4", "D4", "E4"],
        supportPalette: ["E3", "A3", "C4", "E4", "G4"],
        tensionNote: "B3",
        texturePalette: ["A4", "C5", "D5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 165, bandwidth: 0.84, gain: 0.4),
                EQBandConfiguration(filterType: .parametric, frequency: 340, bandwidth: 0.96, gain: -1.6),
                EQBandConfiguration(filterType: .parametric, frequency: 6_200, bandwidth: 0.8, gain: 1.0)
            ],
            reverbPreset: .mediumRoom,
            reverbMix: 8,
            delayTime: 0.018,
            delayFeedback: 1.3,
            delayLowPassCutoff: 4_600,
            delayMix: 1.6,
            spaceVolume: 0.95,
            outputVolume: 0.89
        ),
        baseVelocityScale: 1.04,
        melodyDurationScale: 0.96,
        pulseDurationScale: 0.84,
        cadenceDurationScale: 1.02,
        anchorBaseMidi: 63,
        registerBias: 1
    )
}
