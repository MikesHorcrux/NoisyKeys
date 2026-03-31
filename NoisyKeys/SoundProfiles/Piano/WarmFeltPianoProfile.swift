//
//  WarmFeltPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum WarmFeltPianoProfile {
    static let profile = PianoSoundProfile(
        id: "warm-felt",
        displayName: "Warm Felt",
        summary: "Soft felt with warm body.",
        soundPrefix: "piano-warm-felt",
        programNumber: 0,
        masterGain: -0.5,
        registerMap: PianoRegisterMap(
            bass: ["G3", "A3", "C4", "D4", "E4"],
            low: ["C4", "D4", "E4", "G4", "A4"],
            middle: ["D4", "E4", "G4", "A4", "C5", "D5"],
            upper: ["G4", "A4", "C5", "D5", "E5", "G5"],
            high: ["C5", "D5", "E5", "G5", "A5", "C6"]
        ),
        accentPalette: ["A3", "C4", "D4", "E4", "G4", "A4", "C5"],
        supportPalette: ["C4", "E4", "G4", "A4", "C5"],
        tensionNote: "B3",
        texturePalette: ["D5", "E5", "G5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 160, bandwidth: 0.92, gain: 2.0),
                EQBandConfiguration(filterType: .parametric, frequency: 360, bandwidth: 1.02, gain: -1.4),
                EQBandConfiguration(filterType: .parametric, frequency: 2_450, bandwidth: 0.98, gain: -1.9)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 19,
            delayTime: 0.018,
            delayFeedback: 1.4,
            delayLowPassCutoff: 5_700,
            delayMix: 1.6,
            spaceVolume: 0.93,
            outputVolume: 0.89
        ),
        baseVelocityScale: 0.96,
        melodyDurationScale: 1.12,
        pulseDurationScale: 0.94,
        cadenceDurationScale: 1.15,
        anchorBaseMidi: 61,
        registerBias: -1
    )
}
