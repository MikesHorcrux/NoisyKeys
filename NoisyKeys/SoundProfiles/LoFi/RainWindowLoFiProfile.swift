//
//  RainWindowLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum RainWindowLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "rain-window",
        displayName: "Rain Window",
        summary: "Soft electric keys with sleepy upper air.",
        soundPrefix: "lofi-rain-window",
        programNumber: 5,
        masterGain: -2,
        melodicPalette: ["A3", "C4", "D4", "E4", "G4", "A4", "C5", "D5"],
        accentPalette: ["A3", "D4", "E4", "G4", "A4", "C5"],
        supportPalette: ["A3", "E4", "G4", "A4", "C5"],
        tensionNote: "B4",
        texturePalette: ["D5", "E5", "G5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 180, bandwidth: 0.9, gain: 0.9),
                EQBandConfiguration(filterType: .parametric, frequency: 3_200, bandwidth: 1.1, gain: -2.0),
                EQBandConfiguration(filterType: .parametric, frequency: 7_000, bandwidth: 0.9, gain: -1.6)
            ],
            reverbPreset: .largeHall,
            reverbMix: 24,
            delayTime: 0.11,
            delayFeedback: 7,
            delayLowPassCutoff: 4_000,
            delayMix: 9,
            spaceVolume: 0.93,
            outputVolume: 0.86
        ),
        baseVelocityScale: 0.9,
        melodyDurationScale: 1.12,
        pulseDurationScale: 0.9,
        cadenceDurationScale: 1.14,
        anchorBaseMidi: 58,
        registerBias: 0
    )
}
