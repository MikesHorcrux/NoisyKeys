//
//  ConcertHallPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum ConcertHallPianoProfile {
    static let profile = PianoSoundProfile(
        id: "concert-hall",
        displayName: "Concert Hall",
        summary: "Bright grand with more room.",
        soundPrefix: "piano-concert-hall",
        programNumber: 0,
        masterGain: 0.4,
        registerMap: PianoRegisterMap(
            bass: ["C3", "D3", "E3", "G3", "A3"],
            low: ["A3", "C4", "D4", "E4", "G4"],
            middle: ["C4", "D4", "E4", "G4", "A4", "C5"],
            upper: ["E4", "G4", "A4", "C5", "D5", "E5"],
            high: ["A4", "C5", "D5", "E5", "G5", "A5"]
        ),
        accentPalette: ["G3", "A3", "C4", "D4", "E4", "G4", "A4", "C5"],
        supportPalette: ["C4", "E4", "G4", "A4", "C5"],
        tensionNote: "B3",
        texturePalette: ["E5", "G5", "A5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 165, bandwidth: 0.82, gain: 1.3),
                EQBandConfiguration(filterType: .parametric, frequency: 320, bandwidth: 0.98, gain: -0.9),
                EQBandConfiguration(filterType: .parametric, frequency: 5_200, bandwidth: 0.82, gain: 1.0)
            ],
            reverbPreset: .largeHall,
            reverbMix: 23,
            delayTime: 0.024,
            delayFeedback: 1.6,
            delayLowPassCutoff: 5_800,
            delayMix: 2.4,
            spaceVolume: 0.96,
            outputVolume: 0.91
        ),
        baseVelocityScale: 1.01,
        melodyDurationScale: 1.08,
        pulseDurationScale: 0.94,
        cadenceDurationScale: 1.12,
        anchorBaseMidi: 63,
        registerBias: 0
    )
}
