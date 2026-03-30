//
//  StudyBeatLoFiProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum StudyBeatLoFiProfile {
    static let profile = LoFiSoundProfile(
        id: "study-beat",
        displayName: "Study Beat",
        summary: "Warm Rhodes chords with a head-nod pulse.",
        soundPrefix: "lofi-study-beat",
        programNumber: 4,
        masterGain: -1,
        melodicPalette: ["C3", "D#3", "F3", "G3", "A#3", "C4", "D#4", "F4", "G4", "A#4"],
        accentPalette: ["C3", "F3", "G3", "A#3", "C4", "D#4", "F4"],
        supportPalette: ["C3", "G3", "A#3", "C4", "F4"],
        tensionNote: "D4",
        texturePalette: ["G4", "A#4", "C5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 160, bandwidth: 0.88, gain: 1.2),
                EQBandConfiguration(filterType: .parametric, frequency: 2_900, bandwidth: 1.0, gain: -1.7),
                EQBandConfiguration(filterType: .parametric, frequency: 6_100, bandwidth: 0.82, gain: -1.1)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 17,
            delayTime: 0.08,
            delayFeedback: 6,
            delayLowPassCutoff: 4_600,
            delayMix: 7,
            spaceVolume: 0.95,
            outputVolume: 0.88
        ),
        baseVelocityScale: 0.94,
        melodyDurationScale: 1.08,
        pulseDurationScale: 0.98,
        cadenceDurationScale: 1.06,
        anchorBaseMidi: 56,
        registerBias: -1
    )
}
