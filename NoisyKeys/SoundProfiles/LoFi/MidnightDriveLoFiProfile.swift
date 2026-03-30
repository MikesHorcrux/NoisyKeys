//
//  MidnightDriveLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum MidnightDriveLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "midnight-drive",
        displayName: "Midnight Drive",
        summary: "Dark Rhodes with a heavier low pulse.",
        soundPrefix: "lofi-midnight-drive",
        programNumber: 4,
        masterGain: -1.5,
        melodicPalette: ["C3", "D#3", "F3", "G3", "A#3", "C4", "D#4", "G4", "A#4"],
        accentPalette: ["C3", "G3", "A#3", "C4", "D#4", "F4"],
        supportPalette: ["C3", "G3", "C4", "F4"],
        tensionNote: "B3",
        texturePalette: ["G4", "A#4", "D5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 145, bandwidth: 0.9, gain: 1.5),
                EQBandConfiguration(filterType: .parametric, frequency: 2_700, bandwidth: 1.0, gain: -1.3),
                EQBandConfiguration(filterType: .parametric, frequency: 5_400, bandwidth: 0.8, gain: -1.9)
            ],
            reverbPreset: .mediumRoom,
            reverbMix: 12,
            delayTime: 0.07,
            delayFeedback: 5,
            delayLowPassCutoff: 3_900,
            delayMix: 6,
            spaceVolume: 0.95,
            outputVolume: 0.9
        ),
        baseVelocityScale: 0.98,
        melodyDurationScale: 1.02,
        pulseDurationScale: 1.02,
        cadenceDurationScale: 1.04,
        anchorBaseMidi: 54,
        registerBias: -2
    )
}
