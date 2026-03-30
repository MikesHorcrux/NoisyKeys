//
//  VelvetRoomPianoProfile.swift
//  NoisyKeys
//

import AVFoundation
import Foundation

enum VelvetRoomPianoProfile {
    static let profile = PianoSoundProfile(
        id: "velvet-room",
        displayName: "Velvet Room",
        summary: "Low-lit, close-mic piano for intimate mellow phrases.",
        soundPrefix: "piano-velvet-room",
        programNumber: 2,
        masterGain: -2,
        registerMap: PianoRegisterMap(
            bass: ["D3", "F3", "G3", "A3", "C4"],
            low: ["F3", "G3", "A3", "C4", "D4"],
            middle: ["A3", "C4", "D4", "F4", "G4", "A4"],
            upper: ["D4", "F4", "G4", "A4", "C5", "D5"],
            high: ["G4", "A4", "C5", "D5", "F5", "G5"]
        ),
        accentPalette: ["F3", "G3", "A3", "C4", "D4", "F4", "G4"],
        supportPalette: ["C4", "F4", "G4", "A4"],
        tensionNote: "E4",
        texturePalette: ["C5", "D5", "F5"],
        effectConfiguration: InstrumentEffectConfiguration(
            eqBands: [
                EQBandConfiguration(filterType: .parametric, frequency: 180, bandwidth: 0.92, gain: 1.1),
                EQBandConfiguration(filterType: .parametric, frequency: 320, bandwidth: 1.02, gain: -1.1),
                EQBandConfiguration(filterType: .parametric, frequency: 2_900, bandwidth: 1.0, gain: -1.7)
            ],
            reverbPreset: .mediumChamber,
            reverbMix: 17,
            delayTime: 0.017,
            delayFeedback: 1.1,
            delayLowPassCutoff: 5_100,
            delayMix: 1.4,
            spaceVolume: 0.91,
            outputVolume: 0.85
        ),
        baseVelocityScale: 0.93,
        melodyDurationScale: 1.12,
        pulseDurationScale: 0.9,
        cadenceDurationScale: 1.15,
        anchorBaseMidi: 60,
        registerBias: -1
    )
}
