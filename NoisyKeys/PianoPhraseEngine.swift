//
//  PianoPhraseEngine.swift
//  NoisyKeys
//
//  Created by Codex on 3/30/26.
//

import Foundation

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
        profile: PianoSoundProfile,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        textMood: TypingTextMood,
        usageSnapshot: AdaptiveKeyUsageSnapshot
    ) -> SoundMapping? {
        guard instrument == .piano else {
            return nil
        }

        if state?.performanceStyle != performanceStyle ||
            state?.textMood != textMood ||
            state?.profileID != profile.id {
            state = PianoPhraseState(
                profile: profile,
                performanceStyle: performanceStyle,
                textMood: textMood
            )
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
        profile: PianoSoundProfile,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        textMood: TypingTextMood,
        usageSnapshot: AdaptiveKeyUsageSnapshot
    ) -> SoundMapping? {
        var copy = self
        return copy.mapping(
            for: input,
            instrument: instrument,
            profile: profile,
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
    static func duration(
        for role: KeyboardSoundRole,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        profile: InstrumentProfileSnapshot
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

        let profileScale: Double
        switch role {
        case .melody:
            profileScale = profile.melodyDurationScale
        case .pulse:
            profileScale = profile.pulseDurationScale
        case .cadence:
            profileScale = profile.cadenceDurationScale
        case .tension, .texture, .accent, .navigation:
            profileScale = 1
        }

        return baseDuration * profileScale * durationMultiplier(
            for: role,
            tempo: tempo,
            performanceStyle: performanceStyle
        )
    }

    static func roleVelocityScale(
        for _: KeyboardSoundRole,
        performanceStyle: KeyboardPerformanceStyle,
        profile: InstrumentProfileSnapshot
    ) -> Double {
        let styleScale: Double
        switch performanceStyle {
        case .mellow:
            styleScale = 0.98
        case .warm:
            styleScale = 1
        case .bright:
            styleScale = 1.02
        case .driving:
            styleScale = 1.04
        case .stormy:
            styleScale = 1.05
        }

        return styleScale * profile.baseVelocityScale
    }

    static func effectConfiguration(for profile: InstrumentProfileSnapshot) -> InstrumentEffectConfiguration {
        profile.effectConfiguration
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
    let profileID: String
    let performanceStyle: KeyboardPerformanceStyle
    let textMood: TypingTextMood
    let registerMap: PianoRegisterMap

    private var bandIndices: [PianoKeyboardBand: Int]
    private var bandDirections: [PianoKeyboardBand: Int]
    private var bandEventCounts: [PianoKeyboardBand: Int]
    private var activeBand: PianoKeyboardBand
    private var lastActiveNoteLabel: String?

    init(profile: PianoSoundProfile, performanceStyle: KeyboardPerformanceStyle, textMood: TypingTextMood) {
        self.profileID = profile.id
        self.performanceStyle = performanceStyle
        self.textMood = textMood
        self.registerMap = profile.registerMap
        self.bandIndices = [:]
        self.bandDirections = [:]
        self.bandEventCounts = [:]
        self.activeBand = .middle
        self.lastActiveNoteLabel = nil

        for band in PianoKeyboardBand.allCases {
            let lane = melodicLane(for: band)
            bandIndices[band] = Self.startIndex(for: band, laneCount: lane.count, textMood: textMood)
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

        let lane = melodicLane(for: band)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count, textMood: textMood)
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
        let lane = melodicLane(for: band)
        let cadenceAnchors = Self.cadenceIndices(forLaneCount: lane.count)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count, textMood: textMood)
        let targetIndex = cadenceAnchors.min { abs($0 - currentIndex) < abs($1 - currentIndex) } ?? currentIndex

        bandIndices[band] = targetIndex
        bandDirections[band] = 1

        let noteLabel = lane[targetIndex]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func continuationNote() -> String {
        let band = activeBand
        let lane = melodicLane(for: band)
        let noteLabel = lane[bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count, textMood: textMood)]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func ornamentNote(in band: PianoKeyboardBand, direction: Int) -> String {
        activeBand = band
        let lane = melodicLane(for: band)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count, textMood: textMood)
        let nextIndex = max(0, min(lane.count - 1, currentIndex + direction))
        bandIndices[band] = nextIndex
        let noteLabel = lane[nextIndex]
        lastActiveNoteLabel = noteLabel
        return noteLabel
    }

    private mutating func textureNote(in band: PianoKeyboardBand, offset: Int) -> String {
        activeBand = band
        let lane = melodicLane(for: band)
        let currentIndex = bandIndices[band] ?? Self.startIndex(for: band, laneCount: lane.count, textMood: textMood)
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

        let baseMovement: Int
        switch family {
        case .home:
            baseMovement = 0
        case .open:
            baseMovement = direction
        case .lift:
            baseMovement = 1
        case .warmth:
            baseMovement = eventCount.isMultiple(of: 2) ? 0 : -1
        case .color:
            baseMovement = direction
        case .spark:
            baseMovement = 1
        case .tension:
            baseMovement = performanceStyle == .stormy ? -1 : 1
        }

        return moodAdjustedMovement(
            baseMovement,
            family: family,
            eventCount: eventCount
        )
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

    private func melodicLane(for band: PianoKeyboardBand) -> [String] {
        let lane: [String]
        switch band {
        case .bass:
            lane = registerMap.bass
        case .low:
            lane = registerMap.low
        case .middle:
            lane = registerMap.middle
        case .upper:
            lane = registerMap.upper
        case .high:
            lane = registerMap.high
        }

        return moodAdjustedLane(lane)
    }

    private func moodAdjustedLane(_ lane: [String]) -> [String] {
        guard lane.count > 2 else { return lane }

        switch textMood {
        case .joyful, .playful:
            return Array(lane.suffix(max(2, lane.count - 1)))
        case .tender, .sad:
            return Array(lane.prefix(max(2, lane.count - 1)))
        case .angry:
            return Array(lane.prefix(max(2, lane.count - 2)))
        case .focused:
            if lane.count > 3 {
                return Array(lane.dropFirst().dropLast())
            }
            return lane
        case .tense, .neutral:
            return lane
        }
    }

    private func moodAdjustedMovement(
        _ movement: Int,
        family: AdaptiveNoteFamily,
        eventCount: Int
    ) -> Int {
        switch textMood {
        case .joyful:
            return movement == 0 && family == .home && eventCount.isMultiple(of: 4) ? 1 : movement
        case .playful:
            return movement >= 0 ? max(1, movement) : movement
        case .tender:
            return min(movement, 0)
        case .focused:
            return eventCount.isMultiple(of: 3) ? 0 : movement
        case .sad:
            return min(movement, 0)
        case .angry:
            return family == .tension ? -1 : movement
        case .tense, .neutral:
            return movement
        }
    }

    private static func startIndex(
        for band: PianoKeyboardBand,
        laneCount: Int,
        textMood: TypingTextMood = .neutral
    ) -> Int {
        let offset: Int
        switch textMood {
        case .joyful, .playful:
            offset = 1
        case .tender, .sad, .angry:
            offset = -1
        case .focused, .tense, .neutral:
            offset = 0
        }

        let baseIndex: Int
        switch band {
        case .bass:
            baseIndex = min(2, laneCount - 1)
        case .low:
            baseIndex = min(1, laneCount - 1)
        case .middle:
            baseIndex = min(2, laneCount - 1)
        case .upper:
            baseIndex = min(1, laneCount - 1)
        case .high:
            baseIndex = min(1, laneCount - 1)
        }

        return max(0, min(baseIndex + offset, laneCount - 1))
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
