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
        summary: "Balanced grand piano with a wide cinematic spread.",
        soundPrefix: "piano-concert-hall",
        programNumber: 0,
        masterGain: 0,
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
                EQBandConfiguration(filterType: .parametric, frequency: 175, bandwidth: 0.84, gain: 1.0),
                EQBandConfiguration(filterType: .parametric, frequency: 300, bandwidth: 1.0, gain: -0.6),
                EQBandConfiguration(filterType: .parametric, frequency: 4_600, bandwidth: 0.84, gain: 0.6)
            ],
            reverbPreset: .largeHall,
            reverbMix: 19,
            delayTime: 0.02,
            delayFeedback: 1.3,
            delayLowPassCutoff: 5_400,
            delayMix: 1.8,
            spaceVolume: 0.94,
            outputVolume: 0.89
        ),
        baseVelocityScale: 1,
        melodyDurationScale: 1.04,
        pulseDurationScale: 0.94,
        cadenceDurationScale: 1.08,
        anchorBaseMidi: 62,
        registerBias: 0
    )
}
