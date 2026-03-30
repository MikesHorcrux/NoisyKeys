//
//  CafeTapeLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum CafeTapeLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "cafe-tape",
        displayName: "Cafe Tape",
        summary: "Cozy tape-warmed keys with a brighter coffee-shop bounce.",
        soundPrefix: "lofi-cafe-tape",
        programNumber: 2,
        masterGain: -1,
        melodicPalette: ["C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5"],
        accentPalette: ["C4", "E4", "G4", "A4", "C5", "E5"],
        supportPalette: ["C4", "G4", "A4", "C5"],
        tensionNote: "B4",
        texturePalette: ["E5", "G5", "A5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 165, bandwidth: 0.86, gain: 0.8),
                EQBandConfiguration(filterType: .parametric, frequency: 3_400, bandwidth: 1.0, gain: -1.5),
                EQBandConfiguration(filterType: .parametric, frequency: 6_300, bandwidth: 0.76, gain: -0.6)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 15,
            delayTime: 0.065,
            delayFeedback: 4,
            delayLowPassCutoff: 4_900,
            delayMix: 5,
            spaceVolume: 0.95,
            outputVolume: 0.89
        ),
        baseVelocityScale: 0.92,
        melodyDurationScale: 1.04,
        pulseDurationScale: 0.96,
        cadenceDurationScale: 1.08,
        anchorBaseMidi: 60,
        registerBias: 1
    )
}
