//
//  SidewalkNeonLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum SidewalkNeonLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "sidewalk-neon",
        displayName: "Sidewalk Neon",
        summary: "Sharper electric keys with a late-night city flicker.",
        soundPrefix: "lofi-sidewalk-neon",
        programNumber: 2,
        masterGain: -0.5,
        melodicPalette: ["D3", "F3", "G3", "A3", "C4", "D4", "F4", "G4", "A4", "C5"],
        accentPalette: ["D3", "A3", "C4", "D4", "F4", "A4"],
        supportPalette: ["D3", "A3", "D4", "G4"],
        tensionNote: "C#4",
        texturePalette: ["C5", "D5", "F5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 150, bandwidth: 0.82, gain: 0.6),
                EQBandConfiguration(filterType: .parametric, frequency: 3_600, bandwidth: 1.0, gain: -0.8),
                EQBandConfiguration(filterType: .parametric, frequency: 6_700, bandwidth: 0.72, gain: 0.5)
            ],
            reverbPreset: .mediumRoom,
            reverbMix: 11,
            delayTime: 0.058,
            delayFeedback: 4.5,
            delayLowPassCutoff: 4_800,
            delayMix: 4.5,
            spaceVolume: 0.96,
            outputVolume: 0.9
        ),
        baseVelocityScale: 0.97,
        melodyDurationScale: 0.98,
        pulseDurationScale: 0.9,
        cadenceDurationScale: 1.02,
        anchorBaseMidi: 58,
        registerBias: 1
    )
}
