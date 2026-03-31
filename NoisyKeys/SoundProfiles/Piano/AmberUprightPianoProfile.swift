//
//  AmberUprightPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum AmberUprightPianoProfile {
    static let profile = PianoSoundProfile(
        id: "amber-upright",
        displayName: "Amber Upright",
        summary: "Woody upright with short bounce.",
        soundPrefix: "piano-amber-upright",
        programNumber: 3,
        masterGain: -0.8,
        registerMap: PianoRegisterMap(
            bass: ["F3", "G3", "A3", "C4", "D4"],
            low: ["A3", "C4", "D4", "F4", "G4"],
            middle: ["C4", "D4", "F4", "G4", "A4", "C5"],
            upper: ["F4", "G4", "A4", "C5", "D5", "F5"],
            high: ["A4", "C5", "D5", "F5", "G5", "A5"]
        ),
        accentPalette: ["A3", "C4", "D4", "F4", "G4", "A4", "C5"],
        supportPalette: ["C4", "F4", "G4", "A4", "C5"],
        tensionNote: "B4",
        texturePalette: ["D5", "F5", "G5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 180, bandwidth: 0.84, gain: 1.2),
                EQBandConfiguration(filterType: .parametric, frequency: 620, bandwidth: 0.9, gain: 0.9),
                EQBandConfiguration(filterType: .parametric, frequency: 3_600, bandwidth: 0.9, gain: -0.2)
            ],
            reverbPreset: .mediumRoom,
            reverbMix: 12,
            delayTime: 0.015,
            delayFeedback: 1.1,
            delayLowPassCutoff: 5_300,
            delayMix: 1.3,
            spaceVolume: 0.95,
            outputVolume: 0.9
        ),
        baseVelocityScale: 1.04,
        melodyDurationScale: 1.04,
        pulseDurationScale: 0.92,
        cadenceDurationScale: 1.07,
        anchorBaseMidi: 62,
        registerBias: 0
    )
}
