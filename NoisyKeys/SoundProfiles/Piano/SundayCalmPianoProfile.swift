//
//  SundayCalmPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum SundayCalmPianoProfile {
    static let profile = PianoSoundProfile(
        id: "sunday-calm",
        displayName: "Sunday Calm",
        summary: "Gentle major-key piano that stays soft and breezy.",
        soundPrefix: "piano-sunday-calm",
        programNumber: 0,
        masterGain: -1,
        registerMap: PianoRegisterMap(
            bass: ["C3", "D3", "E3", "G3", "A3"],
            low: ["E3", "G3", "A3", "C4", "D4"],
            middle: ["G3", "A3", "C4", "D4", "E4", "G4"],
            upper: ["C4", "D4", "E4", "G4", "A4", "C5"],
            high: ["E4", "G4", "A4", "C5", "D5", "E5"]
        ),
        accentPalette: ["G3", "A3", "C4", "D4", "E4", "G4", "A4"],
        supportPalette: ["C4", "E4", "G4", "A4"],
        tensionNote: "B3",
        texturePalette: ["D5", "E5", "G5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 168, bandwidth: 0.86, gain: 1.2),
                EQBandConfiguration(filterType: .parametric, frequency: 295, bandwidth: 1.0, gain: -0.7),
                EQBandConfiguration(filterType: .parametric, frequency: 3_100, bandwidth: 1.02, gain: -1.0)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 15,
            delayTime: 0.016,
            delayFeedback: 1.2,
            delayLowPassCutoff: 5_900,
            delayMix: 1.5,
            spaceVolume: 0.93,
            outputVolume: 0.88
        ),
        baseVelocityScale: 0.94,
        melodyDurationScale: 1.1,
        pulseDurationScale: 0.92,
        cadenceDurationScale: 1.12,
        anchorBaseMidi: 61,
        registerBias: 0
    )
}
