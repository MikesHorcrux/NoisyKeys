//
//  DustyRhodesLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum DustyRhodesLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "dusty-rhodes",
        displayName: "Dusty Rhodes",
        summary: "Smoky electric piano with a mellow cassette drag.",
        soundPrefix: "lofi-dusty-rhodes",
        programNumber: 4,
        masterGain: -2,
        melodicPalette: ["F3", "G3", "A3", "C4", "D4", "F4", "G4", "A4", "C5"],
        accentPalette: ["F3", "C4", "D4", "F4", "A4"],
        supportPalette: ["F3", "C4", "F4", "A4"],
        tensionNote: "B3",
        texturePalette: ["C5", "D5", "F5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 155, bandwidth: 0.92, gain: 1.1),
                EQBandConfiguration(filterType: .parametric, frequency: 2_500, bandwidth: 1.1, gain: -1.8),
                EQBandConfiguration(filterType: .parametric, frequency: 5_000, bandwidth: 0.84, gain: -1.4)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 19,
            delayTime: 0.09,
            delayFeedback: 6,
            delayLowPassCutoff: 4_100,
            delayMix: 8,
            spaceVolume: 0.94,
            outputVolume: 0.87
        ),
        baseVelocityScale: 0.91,
        melodyDurationScale: 1.1,
        pulseDurationScale: 0.94,
        cadenceDurationScale: 1.1,
        anchorBaseMidi: 57,
        registerBias: -1
    )
}
