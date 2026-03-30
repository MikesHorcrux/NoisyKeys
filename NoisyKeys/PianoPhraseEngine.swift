//
//  PianoPhraseEngine.swift
//  NoisyKeys
//
//  Created by Codex on 3/30/26.
//

import AVFoundation
import Foundation

struct EQBandConfiguration {
    let filterType: AVAudioUnitEQFilterType
    let frequency: Float
    let bandwidth: Float
    let gain: Float
}

struct InstrumentEffectConfiguration {
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

enum KeyboardSpatialLayout {
    static func column(for keyCode: UInt16) -> Int {
        columns[keyCode] ?? 5
    }

    private static let columns: [UInt16: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8, 29: 9,
        12: 0, 13: 1, 14: 2, 15: 3, 17: 4, 16: 5, 32: 6, 34: 7, 31: 8, 35: 9,
        0: 0, 1: 1, 2: 2, 3: 3, 5: 4, 4: 5, 38: 6, 40: 7, 37: 8,
        6: 1, 7: 2, 8: 3, 9: 4, 11: 5, 45: 6, 46: 7
    ]
}

private enum PianoKeyboardBand: Int, CaseIterable {
    case bass
    case low
    case middle
    case upper
    case high

    init(column: Int) {
        switch column {
        case ..<2:
            self = .bass
        case ..<4:
            self = .low
        case ..<6:
            self = .middle
        case ..<8:
            self = .upper
        default:
            self = .high
        }
    }
}

struct PianoPhraseTracker {
    private var state: PianoPhraseState?

    mutating func mapping(
        for input: KeyboardInput,
        instrument: KeyboardInstrument,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        textMood: TypingTextMood,
        usageSnapshot: AdaptiveKeyUsageSnapshot
    ) -> SoundMapping? {
        guard instrument == .piano else {
            return nil
        }

        if state?.performanceStyle != performanceStyle || state?.textMood != textMood {
            state = PianoPhraseState(performanceStyle: performanceStyle, textMood: textMood)
        }

        guard var state else {
            return nil
        }

        let mapping = state.mapping(for: input, tempo: tempo, usageSnapshot: usageSnapshot)
        self.state = state
        return mapping
    }

    func previewMapping(
        for input: KeyboardInput,
        instrument: KeyboardInstrument,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        textMood: TypingTextMood,
        usageSnapshot: AdaptiveKeyUsageSnapshot
    ) -> SoundMapping? {
        var copy = self
        return copy.mapping(
            for: input,
            instrument: instrument,
            tempo: tempo,
            performanceStyle: performanceStyle,
            textMood: textMood,
            usageSnapshot: usageSnapshot
        )
    }

    mutating func reset() {
        state = nil
    }
}

enum PianoPlaybackProfile {
    static let programNumber: UInt8 = 0
    static let masterGain: Float = 0

    static func duration(
        for role: KeyboardSoundRole,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle
    ) -> TimeInterval {
        let baseDuration: TimeInterval

        switch role {
        case .melody:
            baseDuration = 0.82
        case .pulse:
            baseDuration = 0.24
        case .cadence:
            baseDuration = 1.08
        case .tension:
            baseDuration = 0.5
        case .texture:
            baseDuration = 0.44
        case .accent:
            baseDuration = 0.6
        case .navigation:
            baseDuration = 0.46
        }

        return baseDuration * durationMultiplier(
            for: role,
            tempo: tempo,
            performanceStyle: performanceStyle
        )
    }

    static func roleVelocityScale(
        for _: KeyboardSoundRole,
        performanceStyle: KeyboardPerformanceStyle
    ) -> Double {
        switch performanceStyle {
        case .mellow:
            return 0.98
        case .warm:
            return 1
        case .bright:
            return 1.02
        case .driving:
            return 1.04
        case .stormy:
            return 1.05
        }
    }

    static func effectConfiguration(for performanceStyle: KeyboardPerformanceStyle) -> InstrumentEffectConfiguration {
        switch performanceStyle {
        case .mellow:
            return InstrumentEffectConfiguration(
                eqBands: [
                    EQBandConfiguration(filterType: .parametric, frequency: 170, bandwidth: 0.9, gain: 1.8),
                    EQBandConfiguration(filterType: .parametric, frequency: 310, bandwidth: 1.05, gain: -0.9),
                    EQBandConfiguration(filterType: .parametric, frequency: 2_600, bandwidth: 1.1, gain: -1.6)
                ],
                reverbPreset: .mediumChamber,
                reverbMix: 18,
                delayTime: 0.014,
                delayFeedback: 1.3,
                delayLowPassCutoff: 6_300,
                delayMix: 1.5,
                spaceVolume: 0.92,
                outputVolume: 0.86
            )
        case .warm:
            return InstrumentEffectConfiguration(
                eqBands: [
                    EQBandConfiguration(filterType: .parametric, frequency: 175, bandwidth: 0.86, gain: 1.4),
                    EQBandConfiguration(filterType: .parametric, frequency: 320, bandwidth: 1.0, gain: -0.8),
                    EQBandConfiguration(filterType: .parametric, frequency: 3_000, bandwidth: 1.0, gain: -0.9)
                ],
                reverbPreset: .mediumChamber,
                reverbMix: 14,
                delayTime: 0.018,
                delayFeedback: 1.4,
                delayLowPassCutoff: 5_800,
                delayMix: 1.8,
                spaceVolume: 0.93,
                outputVolume: 0.88
            )
        case .bright:
            return InstrumentEffectConfiguration(
                eqBands: [
                    EQBandConfiguration(filterType: .parametric, frequency: 180, bandwidth: 0.82, gain: 0.5),
                    EQBandConfiguration(filterType: .parametric, frequency: 340, bandwidth: 0.95, gain: -1.2),
                    EQBandConfiguration(filterType: .parametric, frequency: 5_700, bandwidth: 0.78, gain: 1.1)
                ],
                reverbPreset: .mediumRoom,
                reverbMix: 10,
                delayTime: 0.024,
                delayFeedback: 1.8,
                delayLowPassCutoff: 5_100,
                delayMix: 2.3,
                spaceVolume: 0.95,
                outputVolume: 0.89
            )
        case .driving:
            return InstrumentEffectConfiguration(
                eqBands: [
                    EQBandConfiguration(filterType: .parametric, frequency: 170, bandwidth: 0.84, gain: 0.6),
                    EQBandConfiguration(filterType: .parametric, frequency: 360, bandwidth: 1.0, gain: -1.4),
                    EQBandConfiguration(filterType: .parametric, frequency: 5_000, bandwidth: 0.8, gain: 0.8)
                ],
                reverbPreset: .mediumRoom,
                reverbMix: 7,
                delayTime: 0.022,
                delayFeedback: 1.5,
                delayLowPassCutoff: 4_700,
                delayMix: 2.1,
                spaceVolume: 0.95,
                outputVolume: 0.89
            )
        case .stormy:
            return InstrumentEffectConfiguration(
                eqBands: [
                    EQBandConfiguration(filterType: .parametric, frequency: 180, bandwidth: 0.9, gain: 0.9),
                    EQBandConfiguration(filterType: .parametric, frequency: 330, bandwidth: 1.0, gain: -1.5),
                    EQBandConfiguration(filterType: .parametric, frequency: 4_500, bandwidth: 0.84, gain: 0.3)
                ],
                reverbPreset: .mediumRoom,
                reverbMix: 6,
                delayTime: 0.02,
                delayFeedback: 1.2,
                delayLowPassCutoff: 4_200,
                delayMix: 1.6,
                spaceVolume: 0.94,
                outputVolume: 0.88
            )
        }
    }

    private static func durationMultiplier(
        for role: KeyboardSoundRole,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle
    ) -> Double {
        let phraseMultiplier: Double
        switch tempo.intensity {
        case .idle, .relaxed:
            phraseMultiplier = 1.16
        case .steady:
            phraseMultiplier = 1.03
        case .energetic:
            phraseMultiplier = 0.95
        case .frantic:
            phraseMultiplier = 0.88
        }

        let roleBias: Double
        switch role {
        case .melody:
            roleBias = 1.06
        case .pulse:
            roleBias = 0.7
        case .cadence:
            roleBias = 1.12
        case .tension:
            roleBias = 0.96
        case .texture:
            roleBias = 0.94
        case .accent:
            roleBias = 0.98
        case .navigation:
            roleBias = 0.94
        }

        return phraseMultiplier *
            roleBias *
            styleDurationBias(for: role, performanceStyle: performanceStyle) *
            continuityBias(for: role, tempo: tempo)
    }

    private static func styleDurationBias(
        for role: KeyboardSoundRole,
        performanceStyle: KeyboardPerformanceStyle
    ) -> Double {
        switch performanceStyle {
        case .mellow:
            return role == .pulse ? 0.92 : 1.1
        case .warm:
            return role == .pulse ? 0.88 : 1.02
        case .bright:
            return role == .pulse ? 0.64 : 0.96
        case .driving:
            return role == .pulse ? 0.56 : 0.9
        case .stormy:
            return role == .pulse ? 0.52 : 0.86
        }
    }

    private static func continuityBias(
        for role: KeyboardSoundRole,
        tempo: TypingTempoSnapshot
    ) -> Double {
        guard let averageInterval = tempo.averageInterval else {
            return 1
        }

        switch role {
        case .melody, .cadence:
            switch averageInterval {
            case ..<0.18:
                return 1.04
            case ..<0.28:
                return 1.02
            case ..<0.42:
                return 1.01
            default:
                return 1
            }
        case .pulse:
            return averageInterval < 0.28 ? 0.84 : 1
        case .tension, .texture, .accent, .navigation:
            return 1
        }
    }
}

private struct PianoPhraseState {
    let performanceStyle: KeyboardPerformanceStyle
    let textMood: TypingTextMood

    private var bandIndices: [PianoKeyboardBand: Int]
    private var bandDirections: [PianoKeyboardBand: Int]
    private var bandEventCounts: [PianoKeyboardBand: Int]
    private var activeBand: PianoKeyboardBand
    private var lastActiveNoteLabel: String?

    init(performanceStyle: KeyboardPerformanceStyle, textMood: TypingTextMood) {
        self.performanceStyle = performanceStyle
        self.textMood = textMood
        self.bandIndices = [:]
        self.bandDirections = [:]
        self.bandEventCounts = [:]
        self.activeBand = .middle
        self.lastActiveNoteLabel = nil

        for band in PianoKeyboardBand.allCases {
            let lane = Self.melodicLane(for: band, performanceStyle: performanceStyle, textMood: textMood)
            bandIndices[band] = Self.startIndex(for: band, laneCount: lane.count)
            bandDirections[band] = 1
            bandEventCounts[band] = 0
        }
    }

    mutating func mapping(
        for input: KeyboardInput,
        tempo: TypingTempoSnapshot,
        usageSnapshot: AdaptiveKeyUsageSnapshot
    ) -> SoundMapping {
        let band = PianoKeyboardBand(column: KeyboardSpatialLayout.column(for: input.keyCode))

        switch input.symbol {
        case .letter(let character):
            let learnedRank = usageSnapshot.rank ?? Self.alphabetIndex(for: character)
            let family = AdaptiveNoteFamily.family(forRank: learnedRank)
            let noteLabel = nextMelodyNote(in: band, family: family, tempo: tempo)
            return SoundMapping(
                role: .melody,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: family.displayName,
                learnedRank: usageSnapshot.rank
            )
        case .number:
            let noteLabel = ornamentNote(in: band, direction: 1)
            return SoundMapping(
                role: .accent,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Accent",
                learnedRank: nil
            )
        case .punctuation:
            let noteLabel = cadenceNote(in: band)
            return SoundMapping(
                role: .cadence,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Cadence",
                learnedRank: nil
            )
        case .space:
            let noteLabel = continuationNote()
            return SoundMapping(
                role: .pulse,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: Self.pulseFamilyName(for: tempo),
                learnedRank: nil
            )
        case .returnKey:
            let noteLabel = cadenceNote(in: band)
            return SoundMapping(
                role: .cadence,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Cadence",
                learnedRank: nil
            )
        case .delete, .escape:
            let noteLabel = ornamentNote(in: activeBand, direction: -1)
            return SoundMapping(
                role: .tension,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Tension",
                learnedRank: nil
            )
        case .tab:
            let noteLabel = textureNote(in: band, offset: 1)
            return SoundMapping(
                role: .texture,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Texture",
                learnedRank: nil
            )
        case .modifier:
            let noteLabel = textureNote(in: activeBand, offset: 0)
            return SoundMapping(
                role: .texture,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Texture",
                learnedRank: nil
            )
        case .arrow(let arrow):
            let noteLabel = navigationNote(for: arrow)
            return SoundMapping(
                role: .navigation,
                noteLabel: noteLabel,
                baseVelocity: 0.72,
                noteFamilyName: "Navigation",
                learnedRank: nil
            )
        case .unknown:
            return SoundMapping(
                role: .accent,
                noteLabel: continuationNote(),
                baseVelocity: 0.72,
                noteFamilyName: "Accent",
                learnedRank: nil
            )
        }
    }

    private mutating func nextMelodyNote(
        in band: PianoKeyboardBand,
        family: AdaptiveNoteFamily,
        tempo: TypingTempoSnapshot
    ) -> String {
        activeBand = band
        bandEventCounts[band, default: 0] += 1

        let lane = Self.melodicLane(for: band, performanceStyle: performanceStyle, textMood: textMood)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count)
        let movement = requestedMovement(
            for: family,
            tempo: tempo,
            eventCount: bandEventCounts[band, default: 1],
            direction: bandDirections[band, default: 1]
        )
        let nextIndex = boundedIndex(
            currentIndex: currentIndex,
            movement: movement,
            laneCount: lane.count,
            currentDirection: bandDirections[band, default: 1]
        )

        bandIndices[band] = nextIndex.index
        bandDirections[band] = nextIndex.direction

        let noteLabel = lane[nextIndex.index]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func cadenceNote(in band: PianoKeyboardBand) -> String {
        activeBand = band
        let lane = Self.melodicLane(for: band, performanceStyle: performanceStyle, textMood: textMood)
        let cadenceAnchors = Self.cadenceIndices(forLaneCount: lane.count)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count)
        let targetIndex = cadenceAnchors.min { abs($0 - currentIndex) < abs($1 - currentIndex) } ?? currentIndex

        bandIndices[band] = targetIndex
        bandDirections[band] = 1

        let noteLabel = lane[targetIndex]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func continuationNote() -> String {
        let band = activeBand
        let lane = Self.melodicLane(for: band, performanceStyle: performanceStyle, textMood: textMood)
        let noteLabel = lane[bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count)]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func ornamentNote(in band: PianoKeyboardBand, direction: Int) -> String {
        activeBand = band
        let lane = Self.melodicLane(for: band, performanceStyle: performanceStyle, textMood: textMood)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count)
        let nextIndex = max(0, min(lane.count - 1, currentIndex + direction))
        bandIndices[band] = nextIndex
        let noteLabel = lane[nextIndex]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func textureNote(in band: PianoKeyboardBand, offset: Int) -> String {
        activeBand = band
        let lane = Self.melodicLane(for: band, performanceStyle: performanceStyle, textMood: textMood)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count)
        let textureIndex = max(0, min(lane.count - 1, currentIndex + offset))
        let noteLabel = lane[textureIndex]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func navigationNote(for arrow: KeyboardArrowKey) -> String {
        switch arrow {
        case .left:
            activeBand = Self.adjacentBand(to: activeBand, offset: -1)
        case .right:
            activeBand = Self.adjacentBand(to: activeBand, offset: 1)
        case .up:
            return ornamentNote(in: activeBand, direction: 1)
        case .down:
            return ornamentNote(in: activeBand, direction: -1)
        }

        return continuationNote()
    }

    private func requestedMovement(
        for family: AdaptiveNoteFamily,
        tempo: TypingTempoSnapshot,
        eventCount: Int,
        direction: Int
    ) -> Int {
        let gate: Int
        switch tempo.intensity {
        case .idle, .relaxed:
            gate = 3
        case .steady:
            gate = 2
        case .energetic, .frantic:
            gate = 1
        }

        let canMove = eventCount == 1 || eventCount.isMultiple(of: gate)
        guard canMove else {
            return 0
        }

        switch family {
        case .home:
            return 0
        case .open:
            return direction
        case .lift:
            return 1
        case .warmth:
            return eventCount.isMultiple(of: 2) ? 0 : -1
        case .color:
            return direction
        case .spark:
            return 1
        case .tension:
            return performanceStyle == .stormy ? -1 : 1
        }
    }

    private func boundedIndex(
        currentIndex: Int,
        movement: Int,
        laneCount: Int,
        currentDirection: Int
    ) -> (index: Int, direction: Int) {
        guard movement != 0 else {
            return (currentIndex, currentDirection)
        }

        var proposed = currentIndex + movement
        var direction = movement > 0 ? 1 : -1

        if proposed < 0 {
            proposed = min(1, laneCount - 1)
            direction = 1
        } else if proposed >= laneCount {
            proposed = max(0, laneCount - 2)
            direction = -1
        }

        return (proposed, direction)
    }

    private static func melodicLane(
        for band: PianoKeyboardBand,
        performanceStyle: KeyboardPerformanceStyle,
        textMood: TypingTextMood
    ) -> [String] {
        switch band {
        case .bass:
            switch performanceStyle {
            case .mellow, .stormy:
                return textMood == .joyful
                    ? ["A3", "C4", "D4", "E4", "G4"]
                    : ["G3", "A3", "C4", "D4", "E4"]
            case .warm, .driving:
                return ["A3", "C4", "D4", "E4", "G4"]
            case .bright:
                return ["C4", "D4", "E4", "G4", "A4"]
            }
        case .low:
            switch performanceStyle {
            case .mellow, .stormy:
                return ["C4", "D4", "E4", "G4", "A4"]
            case .warm, .driving:
                return ["C4", "D4", "E4", "G4", "A4", "C5"]
            case .bright:
                return ["D4", "E4", "G4", "A4", "C5", "D5"]
            }
        case .middle:
            switch performanceStyle {
            case .mellow:
                return textMood == .joyful
                    ? ["D4", "E4", "G4", "A4", "C5", "D5"]
                    : ["C4", "D4", "E4", "G4", "A4", "C5"]
            case .warm:
                return textMood == .joyful
                    ? ["D4", "E4", "G4", "A4", "C5", "E5"]
                    : ["C4", "D4", "E4", "G4", "A4", "C5"]
            case .bright:
                return ["E4", "G4", "A4", "C5", "D5", "E5"]
            case .driving:
                return ["D4", "E4", "G4", "A4", "C5", "D5"]
            case .stormy:
                return ["C4", "D4", "E4", "G4", "A4", "C5"]
            }
        case .upper:
            switch performanceStyle {
            case .mellow, .warm:
                return ["G4", "A4", "C5", "D5", "E5", "G5"]
            case .bright, .driving:
                return ["A4", "C5", "D5", "E5", "G5", "A5"]
            case .stormy:
                return ["G4", "A4", "C5", "D5", "E5", "G5"]
            }
        case .high:
            switch performanceStyle {
            case .mellow, .warm:
                return ["C5", "D5", "E5", "G5", "A5", "C6"]
            case .bright, .driving:
                return ["D5", "E5", "G5", "A5", "C6", "D6"]
            case .stormy:
                return ["C5", "D5", "E5", "G5", "A5", "C6"]
            }
        }
    }

    private static func startIndex(for band: PianoKeyboardBand, laneCount: Int) -> Int {
        switch band {
        case .bass:
            return min(2, laneCount - 1)
        case .low:
            return min(1, laneCount - 1)
        case .middle:
            return min(2, laneCount - 1)
        case .upper:
            return min(1, laneCount - 1)
        case .high:
            return min(1, laneCount - 1)
        }
    }

    private static func cadenceIndices(forLaneCount laneCount: Int) -> [Int] {
        [1, laneCount / 2, max(laneCount - 2, 0)]
    }

    private static func adjacentBand(to band: PianoKeyboardBand, offset: Int) -> PianoKeyboardBand {
        let proposed = band.rawValue + offset
        let clamped = max(0, min(PianoKeyboardBand.allCases.count - 1, proposed))
        return PianoKeyboardBand.allCases[clamped]
    }

    private static func alphabetIndex(for character: Character) -> Int {
        let normalized = String(character).lowercased()
        guard let asciiValue = normalized.unicodeScalars.first?.value else {
            return 0
        }

        return max(Int(asciiValue) - 97, 0)
    }

    private static func pulseFamilyName(for tempo: TypingTempoSnapshot) -> String {
        switch tempo.intensity {
        case .idle, .relaxed:
            return "Mellow Pulse"
        case .steady:
            return "Phrase Pulse"
        case .energetic, .frantic:
            return "Phrase Trail"
        }
    }
}
