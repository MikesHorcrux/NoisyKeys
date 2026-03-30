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
        summary: "Soft close-up piano with rounded edges and calm weight.",
        soundPrefix: "piano-warm-felt",
        programNumber: 0,
        masterGain: -1,
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
                EQBandConfiguration(filterType: .parametric, frequency: 170, bandwidth: 0.9, gain: 1.7),
                EQBandConfiguration(filterType: .parametric, frequency: 310, bandwidth: 1.04, gain: -1.0),
                EQBandConfiguration(filterType: .parametric, frequency: 2_700, bandwidth: 1.0, gain: -1.5)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 16,
            delayTime: 0.014,
            delayFeedback: 1.1,
            delayLowPassCutoff: 6_200,
            delayMix: 1.2,
            spaceVolume: 0.92,
            outputVolume: 0.87
        ),
        baseVelocityScale: 0.97,
        melodyDurationScale: 1.08,
        pulseDurationScale: 0.9,
        cadenceDurationScale: 1.1,
        anchorBaseMidi: 61,
        registerBias: -1
    )
}
