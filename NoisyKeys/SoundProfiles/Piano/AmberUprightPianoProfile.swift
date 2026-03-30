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
        summary: "A woody upright piano with a little bite in the mids.",
        soundPrefix: "piano-amber-upright",
        programNumber: 3,
        masterGain: -1.5,
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
                EQBandConfiguration(filterType: .parametric, frequency: 170, bandwidth: 0.82, gain: 0.9),
                EQBandConfiguration(filterType: .parametric, frequency: 480, bandwidth: 0.96, gain: 0.5),
                EQBandConfiguration(filterType: .parametric, frequency: 4_200, bandwidth: 0.88, gain: -0.8)
            ],
            reverbPreset: .mediumRoom,
            reverbMix: 10,
            delayTime: 0.012,
            delayFeedback: 0.9,
            delayLowPassCutoff: 5_500,
            delayMix: 1.0,
            spaceVolume: 0.94,
            outputVolume: 0.88
        ),
        baseVelocityScale: 1.02,
        melodyDurationScale: 1.0,
        pulseDurationScale: 0.88,
        cadenceDurationScale: 1.04,
        anchorBaseMidi: 62,
        registerBias: 0
    )
}
