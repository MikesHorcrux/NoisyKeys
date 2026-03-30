//
//  BrightStudioPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum BrightStudioPianoProfile {
    static let profile = PianoSoundProfile(
        id: "bright-studio",
        displayName: "Bright Studio",
        summary: "Forward studio piano with a crisp top and clear attack.",
        soundPrefix: "piano-bright-studio",
        programNumber: 1,
        masterGain: 0,
        registerMap: PianoRegisterMap(
            bass: ["C3", "D3", "E3", "G3", "A3"],
            low: ["D3", "E3", "G3", "A3", "C4"],
            middle: ["E3", "G3", "A3", "C4", "D4", "E4"],
            upper: ["A3", "C4", "D4", "E4", "G4", "A4"],
            high: ["D4", "E4", "G4", "A4", "C5", "D5"]
        ),
        accentPalette: ["E3", "G3", "A3", "C4", "D4", "E4", "G4", "A4"],
        supportPalette: ["C4", "E4", "G4", "A4", "C5"],
        tensionNote: "B4",
        texturePalette: ["E5", "G5", "A5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 170, bandwidth: 0.82, gain: 0.6),
                EQBandConfiguration(filterType: .parametric, frequency: 320, bandwidth: 0.94, gain: -1.0),
                EQBandConfiguration(filterType: .parametric, frequency: 6_000, bandwidth: 0.78, gain: 1.2)
            ],
            reverbPreset: .mediumRoom,
            reverbMix: 9,
            delayTime: 0.014,
            delayFeedback: 1.0,
            delayLowPassCutoff: 5_500,
            delayMix: 1.3,
            spaceVolume: 0.96,
            outputVolume: 0.9
        ),
        baseVelocityScale: 1.05,
        melodyDurationScale: 0.98,
        pulseDurationScale: 0.84,
        cadenceDurationScale: 1.02,
        anchorBaseMidi: 63,
        registerBias: 1
    )
}
