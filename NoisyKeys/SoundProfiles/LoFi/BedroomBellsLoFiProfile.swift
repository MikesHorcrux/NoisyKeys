//
//  BedroomBellsLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum BedroomBellsLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "bedroom-bells",
        displayName: "Bedroom Bells",
        summary: "Soft bell-keys for dreamy late-night typing.",
        soundPrefix: "lofi-bedroom-bells",
        programNumber: 8,
        masterGain: -3,
        melodicPalette: ["C4", "D4", "G4", "A4", "C5", "D5", "G5"],
        accentPalette: ["C4", "G4", "A4", "C5", "D5"],
        supportPalette: ["C4", "G4", "C5", "D5"],
        tensionNote: "B4",
        texturePalette: ["G5", "A5", "C6"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 220, bandwidth: 0.9, gain: -0.4),
                EQBandConfiguration(filterType: .parametric, frequency: 3_800, bandwidth: 1.0, gain: -0.7),
                EQBandConfiguration(filterType: .parametric, frequency: 8_400, bandwidth: 0.85, gain: 0.4)
            ],
            reverbPreset: .cathedral,
            reverbMix: 28,
            delayTime: 0.14,
            delayFeedback: 8,
            delayLowPassCutoff: 4_200,
            delayMix: 11,
            spaceVolume: 0.92,
            outputVolume: 0.84
        ),
        baseVelocityScale: 0.86,
        melodyDurationScale: 1.14,
        pulseDurationScale: 0.88,
        cadenceDurationScale: 1.18,
        anchorBaseMidi: 64,
        registerBias: 2
    )
}
