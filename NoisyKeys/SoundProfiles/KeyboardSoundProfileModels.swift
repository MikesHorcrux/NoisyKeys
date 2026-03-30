//
//  KeyboardSoundProfileModels.swift
//  NoisyKeys
//
//  Created by Codex on 3/30/26.
//

import AVFoundation
import Foundation

struct EQBandConfiguration: Equatable {
    let filterType: AVAudioUnitEQFilterType
    let frequency: Float
    let bandwidth: Float
    let gain: Float
}

struct InstrumentEffectConfiguration: Equatable {
    let eqBands: [EQBandConfiguration]
    let reverbPreset: AVAudioUnitReverbPreset
    let reverbMix: Float
    let delayTime: TimeInterval
    let delayFeedback: Float
    let delayLowPassCutoff: Float
    let delayMix: Float
    let spaceVolume: Float
    let outputVolume: Float
}

struct InstrumentProfileSnapshot: Equatable {
    let id: String
    let displayName: String
    let summary: String
    let soundPrefix: String
    let programNumber: UInt8
    let masterGain: Float
    let melodicPalette: [String]
    let accentPalette: [String]
    let supportPalette: [String]
    let tensionNote: String
    let texturePalette: [String]
    let effectConfiguration: InstrumentEffectConfiguration
    let baseVelocityScale: Double
    let melodyDurationScale: Double
    let pulseDurationScale: Double
    let cadenceDurationScale: Double
    let anchorBaseMidi: Int
    let registerBias: Int
}

struct PianoRegisterMap: Equatable {
    let bass: [String]
    let low: [String]
    let middle: [String]
    let upper: [String]
    let high: [String]
}

struct PianoSoundProfile: Identifiable, Equatable {
    let id: String
    let displayName: String
    let summary: String
    let soundPrefix: String
    let programNumber: UInt8
    let masterGain: Float
    let registerMap: PianoRegisterMap
    let accentPalette: [String]
    let supportPalette: [String]
    let tensionNote: String
    let texturePalette: [String]
    let effectConfiguration: InstrumentEffectConfiguration
    let baseVelocityScale: Double
    let melodyDurationScale: Double
    let pulseDurationScale: Double
    let cadenceDurationScale: Double
    let anchorBaseMidi: Int
    let registerBias: Int

    var snapshot: InstrumentProfileSnapshot {
        InstrumentProfileSnapshot(
            id: id,
            displayName: displayName,
            summary: summary,
            soundPrefix: soundPrefix,
            programNumber: programNumber,
            masterGain: masterGain,
            melodicPalette: uniqueNotes(
                registerMap.middle + registerMap.upper + registerMap.low + registerMap.high + registerMap.bass
            ),
            accentPalette: accentPalette,
            supportPalette: supportPalette,
            tensionNote: tensionNote,
            texturePalette: texturePalette,
            effectConfiguration: effectConfiguration,
            baseVelocityScale: baseVelocityScale,
            melodyDurationScale: melodyDurationScale,
            pulseDurationScale: pulseDurationScale,
            cadenceDurationScale: cadenceDurationScale,
            anchorBaseMidi: anchorBaseMidi,
            registerBias: registerBias
        )
    }

    private func uniqueNotes(_ notes: [String]) -> [String] {
        var seen = Set<String>()
        return notes.filter { seen.insert($0).inserted }
    }
}

struct LoFiSoundProfile: Identifiable, Equatable {
    let id: String
    let displayName: String
    let summary: String
    let soundPrefix: String
    let programNumber: UInt8
    let masterGain: Float
    let melodicPalette: [String]
    let accentPalette: [String]
    let supportPalette: [String]
    let tensionNote: String
    let texturePalette: [String]
    let effectConfiguration: InstrumentEffectConfiguration
    let baseVelocityScale: Double
    let melodyDurationScale: Double
    let pulseDurationScale: Double
    let cadenceDurationScale: Double
    let anchorBaseMidi: Int
    let registerBias: Int

    var snapshot: InstrumentProfileSnapshot {
        InstrumentProfileSnapshot(
            id: id,
            displayName: displayName,
            summary: summary,
            soundPrefix: soundPrefix,
            programNumber: programNumber,
            masterGain: masterGain,
            melodicPalette: melodicPalette,
            accentPalette: accentPalette,
            supportPalette: supportPalette,
            tensionNote: tensionNote,
            texturePalette: texturePalette,
            effectConfiguration: effectConfiguration,
            baseVelocityScale: baseVelocityScale,
            melodyDurationScale: melodyDurationScale,
            pulseDurationScale: pulseDurationScale,
            cadenceDurationScale: cadenceDurationScale,
            anchorBaseMidi: anchorBaseMidi,
            registerBias: registerBias
        )
    }
}

struct ProfileOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let summary: String
}

enum PianoProfileCatalog {
    static let all: [PianoSoundProfile] = [
        ConcertHallPianoProfile.profile,
        WarmFeltPianoProfile.profile,
        MoonlightPianoProfile.profile,
        SundayCalmPianoProfile.profile,
        AmberUprightPianoProfile.profile,
        VelvetRoomPianoProfile.profile,
        GlassNoirPianoProfile.profile,
        BrightStudioPianoProfile.profile
    ]

    static let defaultProfile = WarmFeltPianoProfile.profile

    static func profile(for id: String) -> PianoSoundProfile {
        all.first(where: { $0.id == id }) ?? defaultProfile
    }
}

enum LoFiProfileCatalog {
    static let all: [LoFiSoundProfile] = [
        StudyBeatLoFiProfile.profile,
        RainWindowLoFiProfile.profile,
        MidnightDriveLoFiProfile.profile,
        CafeTapeLoFiProfile.profile,
        DustyRhodesLoFiProfile.profile,
        SunsetCassetteLoFiProfile.profile,
        SidewalkNeonLoFiProfile.profile,
        BedroomBellsLoFiProfile.profile
    ]

    static let defaultProfile = StudyBeatLoFiProfile.profile

    static func profile(for id: String) -> LoFiSoundProfile {
        all.first(where: { $0.id == id }) ?? defaultProfile
    }
}
