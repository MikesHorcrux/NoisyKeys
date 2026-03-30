//
//  SunsetCassetteLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum SunsetCassetteLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "sunset-cassette",
        displayName: "Sunset Cassette",
        summary: "Golden-hour keys with soft stereo tails.",
        soundPrefix: "lofi-sunset-cassette",
        programNumber: 5,
        masterGain: -1.5,
        melodicPalette: ["G3", "A3", "C4", "D4", "E4", "G4", "A4", "C5", "D5"],
        accentPalette: ["G3", "C4", "D4", "E4", "G4", "C5"],
        supportPalette: ["G3", "D4", "G4", "A4"],
        tensionNote: "F4",
        texturePalette: ["D5", "E5", "G5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 170, bandwidth: 0.84, gain: 0.9),
                EQBandConfiguration(filterType: .parametric, frequency: 3_000, bandwidth: 1.0, gain: -1.4),
                EQBandConfiguration(filterType: .parametric, frequency: 6_800, bandwidth: 0.8, gain: -0.9)
            ],
            reverbPreset: .largeHall,
            reverbMix: 20,
            delayTime: 0.095,
            delayFeedback: 6.5,
            delayLowPassCutoff: 4_500,
            delayMix: 8.5,
            spaceVolume: 0.94,
            outputVolume: 0.88
        ),
        baseVelocityScale: 0.9,
        melodyDurationScale: 1.08,
        pulseDurationScale: 0.95,
        cadenceDurationScale: 1.12,
        anchorBaseMidi: 59,
        registerBias: 0
    )
}
