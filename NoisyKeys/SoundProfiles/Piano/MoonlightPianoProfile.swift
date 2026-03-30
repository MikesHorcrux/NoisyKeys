//
//  MoonlightPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum MoonlightPianoProfile {
    static let profile = PianoSoundProfile(
        id: "moonlight",
        displayName: "Moonlight",
        summary: "Moody minor-leaning piano with cooler top notes.",
        soundPrefix: "piano-moonlight",
        programNumber: 2,
        masterGain: -1.5,
        registerMap: PianoRegisterMap(
            bass: ["A2", "C3", "D3", "E3", "G3"],
            low: ["A3", "C4", "D4", "E4", "G4"],
            middle: ["C4", "D4", "E4", "G4", "A4", "C5"],
            upper: ["E4", "G4", "A4", "C5", "D5", "E5"],
            high: ["A4", "C5", "D5", "E5", "G5", "A5"]
        ),
        accentPalette: ["A3", "C4", "D4", "E4", "G4", "A4", "C5"],
        supportPalette: ["A3", "E4", "G4", "A4", "C5"],
        tensionNote: "B4",
        texturePalette: ["E5", "G5", "A5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 185, bandwidth: 0.88, gain: 0.8),
                EQBandConfiguration(filterType: .parametric, frequency: 320, bandwidth: 1.0, gain: -1.2),
                EQBandConfiguration(filterType: .parametric, frequency: 3_800, bandwidth: 0.9, gain: -0.6)
            ],
            reverbPreset: .largeHall,
            reverbMix: 22,
            delayTime: 0.024,
            delayFeedback: 1.6,
            delayLowPassCutoff: 4_900,
            delayMix: 2.2,
            spaceVolume: 0.92,
            outputVolume: 0.86
        ),
        baseVelocityScale: 0.95,
        melodyDurationScale: 1.12,
        pulseDurationScale: 0.92,
        cadenceDurationScale: 1.14,
        anchorBaseMidi: 60,
        registerBias: -1
    )
}
