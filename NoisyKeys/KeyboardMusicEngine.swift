//
//  KeyboardMusicEngine.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/30/26.
//

import AppKit
import CoreGraphics
import Foundation

enum KeyboardInstrument: String, CaseIterable, Identifiable {
    case piano
    case loFiKeys

    var id: Self { self }

    var displayName: String {
        switch self {
        case .piano:
            "Piano"
        case .loFiKeys:
            "Lo-Fi Keys"
        }
    }

    fileprivate var soundPrefix: String {
        switch self {
        case .piano:
            "piano"
        case .loFiKeys:
            "lofi-keys"
        }
    }

    fileprivate var melodicPalette: [String] {
        switch self {
        case .piano:
            ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5"]
        case .loFiKeys:
            ["C3", "D3", "E3", "G3", "A3", "C4", "D4", "E4", "G4", "A4", "C5", "D5"]
        }
    }

    fileprivate var accentPalette: [String] {
        switch self {
        case .piano:
            ["G3", "A3", "B3", "C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
        case .loFiKeys:
            ["A2", "C3", "D3", "E3", "G3", "A3", "C4", "D4", "E4", "G4"]
        }
    }

    fileprivate var bassNote: String {
        switch self {
        case .piano:
            "G3"
        case .loFiKeys:
            "C3"
        }
    }

    fileprivate var pulseNote: String {
        switch self {
        case .piano:
            "G4"
        case .loFiKeys:
            "G3"
        }
    }

    fileprivate var supportPalette: [String] {
        switch self {
        case .piano:
            ["C4", "D4", "E4", "G4", "A4", "C5", "E5"]
        case .loFiKeys:
            ["C3", "E3", "G3", "A3", "C4", "E4", "G4"]
        }
    }

    fileprivate var tensionNote: String {
        switch self {
        case .piano:
            "B3"
        case .loFiKeys:
            "B2"
        }
    }

    fileprivate var textureNote: String {
        switch self {
        case .piano:
            "E5"
        case .loFiKeys:
            "D4"
        }
    }
}

enum KeyboardSoundRole: String {
    case melody
    case pulse
    case cadence
    case tension
    case texture
    case accent
    case navigation

    var displayName: String {
        rawValue.capitalized
    }
}

enum KeyboardModifierKey: String, Hashable {
    case command = "Command"
    case shift = "Shift"
    case capsLock = "Caps Lock"
    case option = "Option"
    case control = "Control"
    case function = "Function"
}

enum KeyboardArrowKey: String, Hashable {
    case left = "Left Arrow"
    case right = "Right Arrow"
    case up = "Up Arrow"
    case down = "Down Arrow"
}

enum KeyboardSymbol: Hashable {
    case letter(Character)
    case number(Character)
    case punctuation(Character)
    case space
    case tab
    case returnKey
    case delete
    case escape
    case modifier(KeyboardModifierKey)
    case arrow(KeyboardArrowKey)
    case unknown(UInt16)

    var label: String {
        switch self {
        case .letter(let character):
            String(character).uppercased()
        case .number(let character):
            String(character)
        case .punctuation(let character):
            punctuationLabel(for: character)
        case .space:
            "Space"
        case .tab:
            "Tab"
        case .returnKey:
            "Return"
        case .delete:
            "Delete"
        case .escape:
            "Escape"
        case .modifier(let modifier):
            modifier.rawValue
        case .arrow(let arrow):
            arrow.rawValue
        case .unknown(let keyCode):
            "Key code \(keyCode)"
        }
    }

    var assetKey: String {
        switch self {
        case .letter(let character):
            String(character).lowercased()
        case .number(let character):
            String(character)
        case .punctuation(let character):
            punctuationAssetKey(for: character)
        case .space:
            "space"
        case .tab:
            "tab"
        case .returnKey:
            "return"
        case .delete:
            "delete"
        case .escape:
            "escape"
        case .modifier(let modifier):
            modifier.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")
        case .arrow(let arrow):
            arrow.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")
        case .unknown(let keyCode):
            "key-\(keyCode)"
        }
    }

    var learnedKeyID: String? {
        switch self {
        case .letter(let character):
            String(character).lowercased()
        default:
            nil
        }
    }

    var learnedKeyLabel: String? {
        switch self {
        case .letter(let character):
            String(character).uppercased()
        default:
            nil
        }
    }

    var dashboardCharacterDelta: Int {
        switch self {
        case .letter, .number, .punctuation, .space, .tab:
            1
        case .delete:
            -1
        case .returnKey, .escape, .modifier, .arrow, .unknown:
            0
        }
    }

    var dashboardHeatKeyID: String? {
        switch self {
        case .letter(let character):
            String(character).lowercased()
        default:
            nil
        }
    }

    var contributesToBurstIdentity: Bool {
        switch self {
        case .letter, .number, .punctuation:
            true
        case .space, .tab, .returnKey, .delete, .escape, .modifier, .arrow, .unknown:
            false
        }
    }

    var isBurstBoundary: Bool {
        switch self {
        case .space, .tab, .returnKey, .punctuation:
            true
        case .letter, .number, .delete, .escape, .modifier, .arrow, .unknown:
            false
        }
    }
}

enum KeyboardInputSource: String {
    case localApp = "NoisyKeys"
    case systemWide = "Everywhere"
}

struct KeyboardInput: Equatable {
    let symbol: KeyboardSymbol
    let keyCode: UInt16
    let source: KeyboardInputSource
    let timestamp: Date
}

enum TypingIntensity: String, Equatable {
    case idle
    case relaxed
    case steady
    case energetic
    case frantic

    var displayName: String {
        rawValue.capitalized
    }
}

struct TypingTempoSnapshot: Equatable {
    let averageInterval: TimeInterval?
    let notesPerSecond: Double
    let beatsPerMinute: Int
    let intensity: TypingIntensity

    static let idle = TypingTempoSnapshot(
        averageInterval: nil,
        notesPerSecond: 0,
        beatsPerMinute: 72,
        intensity: .idle
    )

    var summary: String {
        if intensity == .idle {
            return "Idle"
        }

        return "\(beatsPerMinute) BPM · \(intensity.displayName)"
    }
}

enum TypingTextMood: String, Equatable {
    case neutral
    case joyful
    case playful
    case tender
    case focused
    case tense
    case angry
    case sad

    var displayName: String {
        rawValue.capitalized
    }
}

enum KeyboardPerformanceStyle: String, Equatable {
    case mellow
    case warm
    case bright
    case driving
    case stormy

    var displayName: String {
        switch self {
        case .mellow:
            "Mellow"
        case .warm:
            "Warm"
        case .bright:
            "Bright"
        case .driving:
            "Driving"
        case .stormy:
            "Stormy"
        }
    }

    func summary(for instrument: KeyboardInstrument, textMood: TypingTextMood) -> String {
        if instrument == .piano {
            return "\(displayName) piano · \(textMood.displayName.lowercased()) tone"
        }

        return "\(instrument.displayName) · \(textMood.displayName.lowercased()) tone"
    }

    static func forInstrument(
        _ instrument: KeyboardInstrument,
        tempo: TypingTempoSnapshot,
        expression: TypingExpressionSnapshot
    ) -> KeyboardPerformanceStyle {
        guard instrument == .piano else {
            return .warm
        }

        switch expression.textMood {
        case .joyful:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .mellow
            case .steady:
                return .warm
            case .energetic, .frantic:
                return .bright
            }
        case .playful:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .warm
            case .steady, .energetic, .frantic:
                return .bright
            }
        case .tender:
            switch tempo.intensity {
            case .idle, .relaxed, .steady:
                return .mellow
            case .energetic, .frantic:
                return .warm
            }
        case .focused:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .warm
            case .steady:
                return .warm
            case .energetic, .frantic:
                return .driving
            }
        case .tense:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .warm
            case .steady:
                return .driving
            case .energetic, .frantic:
                return .stormy
            }
        case .angry:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .driving
            case .steady:
                return .driving
            case .energetic, .frantic:
                return .stormy
            }
        case .sad:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .mellow
            case .steady:
                return .mellow
            case .energetic, .frantic:
                return .warm
            }
        case .neutral:
            switch tempo.intensity {
            case .idle, .relaxed:
                return .mellow
            case .steady:
                return .warm
            case .energetic, .frantic:
                return .driving
            }
        }
    }
}

struct TypingExpressionSnapshot: Equatable {
    let textMood: TypingTextMood
    let recentText: String
    let positiveScore: Double
    let negativeScore: Double
    let tensionScore: Double
    let vibeSource: TypingVibeSource
    let vibeConfidence: Double
    let vibeEnergy: Double
    let vibeValence: Double
    let vibeResponseIntensity: TypingVibeResponseIntensity

    var summary: String {
        "\(textMood.displayName) tone · \(vibeSource.displayName)"
    }

    func applying(_ vibeSnapshot: TypingVibeSnapshot?) -> TypingExpressionSnapshot {
        guard let vibeSnapshot,
              vibeSnapshot.isEnabled,
              vibeSnapshot.source != .disabled,
              vibeSnapshot.confidence >= 0.42 else {
            return self
        }

        return TypingExpressionSnapshot(
            textMood: vibeSnapshot.textMood,
            recentText: recentText,
            positiveScore: positiveScore,
            negativeScore: negativeScore,
            tensionScore: tensionScore,
            vibeSource: vibeSnapshot.source,
            vibeConfidence: vibeSnapshot.confidence,
            vibeEnergy: vibeSnapshot.energy,
            vibeValence: vibeSnapshot.valence,
            vibeResponseIntensity: vibeSnapshot.responseIntensity
        )
    }
}

struct SoundTriggerPlan: Equatable {
    let instrument: KeyboardInstrument
    let profile: InstrumentProfileSnapshot
    let role: KeyboardSoundRole
    let soundID: String
    let noteLabel: String
    let noteFamilyName: String
    let keyLabel: String
    let source: KeyboardInputSource
    let tempo: TypingTempoSnapshot
    let textMood: TypingTextMood
    let performanceStyle: KeyboardPerformanceStyle
    let sustainPedalEngaged: Bool
    let velocity: Double
    let learnedRank: Int?
    let vibeSource: TypingVibeSource
    let vibeConfidence: Double
    let vibeEnergy: Double
    let vibeValence: Double
    let vibeResponseIntensity: TypingVibeResponseIntensity

    var debugSummary: String {
        let confidence = Int((vibeConfidence * 100).rounded())
        return "\(profile.displayName) \(role.displayName) \(noteLabel) \(noteFamilyName) for \(keyLabel) · \(performanceStyle.displayName) · \(textMood.displayName) · \(vibeSource.displayName) \(confidence)% · \(tempo.summary) · \(source.rawValue)"
    }
}

struct KeyboardMusicEngine {
    var instrument: KeyboardInstrument = .piano

    private var burstTracker = TypingBurstTracker()
    private var cadenceTracker = TypingCadenceTracker()
    private var dashboardTracker = TypingDashboardTracker()
    private var usageProfile: AdaptiveKeyLearningProfile
    private var expressionTracker = TypingExpressionTracker()
    private var performanceBurstLock = TypingPerformanceBurstLock()
    private var pianoPhraseTracker = PianoPhraseTracker()
    private var externalVibeSnapshot: TypingVibeSnapshot?
    private var pianoProfile = PianoProfileCatalog.defaultProfile
    private var customPianoSettings = CustomPianoSettings.default
    private var loFiProfile = LoFiProfileCatalog.defaultProfile
    private var soundMode = KeyboardSoundMode.feltBloom
    private var lastLeadNoteLabel: String?
    private(set) var lastTempo = TypingTempoSnapshot.idle
    private(set) var learnedKeysSummary: String
    private(set) var adaptiveMappingDescription: String
    private(set) var performanceDescription: String
    private(set) var dashboardSpeedSummary = "0 WPM"

    init(instrument: KeyboardInstrument = .piano, persistentLearning: Bool = false) {
        self.instrument = instrument
        soundMode = KeyboardSoundMode.preferredMode(
            for: instrument,
            profileID: instrument == .piano ? PianoProfileCatalog.defaultProfile.id : LoFiProfileCatalog.defaultProfile.id
        )
        switch soundMode {
        case .grandRoom:
            pianoProfile = ConcertHallPianoProfile.profile
        case .feltBloom:
            pianoProfile = WarmFeltPianoProfile.profile
        case .jazzClub:
            pianoProfile = AmberUprightPianoProfile.profile
        case .midnightBlue:
            pianoProfile = MoonlightPianoProfile.profile
        case .customMix:
            pianoProfile = CustomPianoProfileBuilder.makeProfile(from: customPianoSettings)
        }
        usageProfile = AdaptiveKeyLearningProfile(persistentLearning: persistentLearning)
        learnedKeysSummary = usageProfile.topKeysSummary
        adaptiveMappingDescription = usageProfile.defaultDescription
        let defaultProfile = instrument == .piano ? pianoProfile.snapshot : loFiProfile.snapshot
        performanceDescription = Self.defaultPerformanceDescription(
            for: defaultProfile,
            mode: soundMode,
            instrument: instrument
        )
    }

    var selectedPianoProfile: PianoSoundProfile { pianoProfile }

    var selectedLoFiProfile: LoFiSoundProfile { loFiProfile }

    var currentSoundMode: KeyboardSoundMode { soundMode }

    var currentCustomPianoSettings: CustomPianoSettings { customPianoSettings }

    var topKeyStats: [AdaptiveKeyStat] {
        dashboardTracker.topKeyStats
    }

    var lastTempoSnapshot: TypingTempoSnapshot {
        lastTempo
    }

    var currentProfileDisplayName: String {
        currentProfileSnapshot.displayName
    }

    var currentProfileSummary: String {
        currentProfileSnapshot.summary
    }

    mutating func plan(for input: KeyboardInput) -> SoundTriggerPlan {
        let startsNewBurst = burstTracker.register(at: input.timestamp)
        if startsNewBurst {
            cadenceTracker.reset()
            expressionTracker.reset()
            performanceBurstLock.reset()
            pianoPhraseTracker.reset()
            lastLeadNoteLabel = nil
        }

        let tempo = cadenceTracker.register(at: input.timestamp)
        let dashboardSnapshot = dashboardTracker.register(symbol: input.symbol, at: input.timestamp)
        let usageSnapshot = usageProfile.register(symbol: input.symbol)
        let expressionSnapshot = expressionTracker
            .register(symbol: input.symbol)
            .applying(externalVibeSnapshot)
        let burstPerformance = performanceBurstLock.resolve(
            for: input.symbol,
            instrument: instrument,
            tempo: tempo,
            expressionSnapshot: expressionSnapshot
        )
        let phraseMapping = pianoPhraseTracker.mapping(
            for: input,
            instrument: instrument,
            profile: pianoProfile,
            tempo: tempo,
            performanceStyle: burstPerformance.performanceStyle,
            textMood: burstPerformance.textMood,
            usageSnapshot: usageSnapshot
        )
        let currentProfile = currentProfileSnapshot
        lastTempo = tempo
        let plan = KeyboardSoundPlanner.plan(
            for: input,
            instrument: instrument,
            profile: currentProfile,
            tempo: tempo,
            textMood: burstPerformance.textMood,
            performanceStyle: burstPerformance.performanceStyle,
            usageSnapshot: usageSnapshot,
            previousLeadNoteLabel: lastLeadNoteLabel,
            mappingOverride: phraseMapping,
            expressionSnapshot: expressionSnapshot
        )
        if plan.role.shouldInfluenceVoiceLeading {
            lastLeadNoteLabel = plan.noteLabel
        }
        learnedKeysSummary = usageProfile.topKeysSummary
        adaptiveMappingDescription = usageProfile.description(for: input.symbol, snapshot: usageSnapshot)
        performanceDescription = Self.performanceDescription(for: plan, mode: soundMode)
        dashboardSpeedSummary = Self.dashboardSpeedSummary(
            wordsPerMinute: dashboardSnapshot.wordsPerMinute,
            intensity: tempo.intensity
        )
        return plan
    }

    func previewPlan(for symbol: KeyboardSymbol, source: KeyboardInputSource = .localApp) -> SoundTriggerPlan {
        let input = KeyboardInput(symbol: symbol, keyCode: 0, source: source, timestamp: Date())
        let previewExpression = expressionTracker
            .preview(after: symbol)
            .applying(externalVibeSnapshot)
        let previewPerformance = performanceBurstLock.preview(
            for: symbol,
            instrument: instrument,
            tempo: lastTempo,
            expressionSnapshot: previewExpression,
            prefersLockedBurst: burstTracker.isActive(at: input.timestamp)
        )
        let previewMapping = pianoPhraseTracker.previewMapping(
            for: input,
            instrument: instrument,
            profile: pianoProfile,
            tempo: lastTempo,
            performanceStyle: previewPerformance.performanceStyle,
            textMood: previewPerformance.textMood,
            usageSnapshot: usageProfile.snapshot(for: symbol)
        )
        return KeyboardSoundPlanner.plan(
            for: input,
            instrument: instrument,
            profile: currentProfileSnapshot,
            tempo: lastTempo,
            textMood: previewPerformance.textMood,
            performanceStyle: previewPerformance.performanceStyle,
            usageSnapshot: usageProfile.snapshot(for: symbol),
            previousLeadNoteLabel: lastLeadNoteLabel,
            mappingOverride: previewMapping,
            expressionSnapshot: previewExpression
        )
    }

    mutating func setTypingVibeSnapshot(_ snapshot: TypingVibeSnapshot) {
        externalVibeSnapshot = snapshot.isEnabled ? snapshot : nil
    }

    mutating func setSoundMode(_ mode: KeyboardSoundMode) {
        soundMode = mode

        switch mode {
        case .grandRoom:
            instrument = .piano
            pianoProfile = ConcertHallPianoProfile.profile
        case .feltBloom:
            instrument = .piano
            pianoProfile = WarmFeltPianoProfile.profile
        case .jazzClub:
            instrument = .piano
            pianoProfile = AmberUprightPianoProfile.profile
        case .midnightBlue:
            instrument = .piano
            pianoProfile = MoonlightPianoProfile.profile
        case .customMix:
            instrument = .piano
            pianoProfile = CustomPianoProfileBuilder.makeProfile(from: customPianoSettings)
        }

        resetCurrentInstrumentState()
    }

    mutating func setCustomPianoSettings(_ settings: CustomPianoSettings) {
        customPianoSettings = settings
        guard instrument == .piano else { return }
        guard soundMode == .customMix else { return }

        pianoProfile = CustomPianoProfileBuilder.makeProfile(from: settings)
        resetCurrentInstrumentState()
    }

    private var currentProfileSnapshot: InstrumentProfileSnapshot {
        switch instrument {
        case .piano:
            pianoProfile.snapshot
        case .loFiKeys:
            loFiProfile.snapshot
        }
    }

    private mutating func resetCurrentInstrumentState() {
        burstTracker.reset()
        cadenceTracker.reset()
        expressionTracker.reset()
        performanceBurstLock.reset()
        pianoPhraseTracker.reset()
        lastLeadNoteLabel = nil
        lastTempo = .idle
        learnedKeysSummary = usageProfile.topKeysSummary
        adaptiveMappingDescription = usageProfile.defaultDescription
        performanceDescription = Self.defaultPerformanceDescription(
            for: currentProfileSnapshot,
            mode: soundMode,
            instrument: instrument
        )
    }

    private static func defaultPerformanceDescription(
        for profile: InstrumentProfileSnapshot,
        mode: KeyboardSoundMode,
        instrument: KeyboardInstrument
    ) -> String {
        switch instrument {
        case .piano:
            return "\(mode.displayName) · piano profile"
        case .loFiKeys:
            return "\(mode.displayName) · fixed lo-fi vibe"
        }
    }

    private static func performanceDescription(for plan: SoundTriggerPlan, mode: KeyboardSoundMode) -> String {
        switch plan.instrument {
        case .piano:
            return "\(mode.displayName) · \(plan.performanceStyle.displayName) phrase"
        case .loFiKeys:
            return "\(mode.displayName) · \(mode.summary)"
        }
    }

    private static func dashboardSpeedSummary(wordsPerMinute: Int, intensity: TypingIntensity) -> String {
        guard wordsPerMinute > 0 else {
            return "0 WPM"
        }

        return "\(wordsPerMinute) WPM · \(intensity.displayName)"
    }
}

struct TypingCadenceTracker {
    private var timestamps: [Date] = []
    private let maxHistory = 16

    mutating func register(at timestamp: Date) -> TypingTempoSnapshot {
        timestamps.append(timestamp)

        if timestamps.count > maxHistory {
            timestamps.removeFirst(timestamps.count - maxHistory)
        }

        guard timestamps.count > 1 else {
            return TypingTempoSnapshot(
                averageInterval: nil,
                notesPerSecond: 0,
                beatsPerMinute: 72,
                intensity: .relaxed
            )
        }

        let intervals = zip(timestamps.dropFirst(), timestamps).map { newer, older in
            newer.timeIntervalSince(older)
        }
        let positiveIntervals = intervals.filter { $0 > 0 }
        guard !positiveIntervals.isEmpty else {
            return TypingTempoSnapshot(
                averageInterval: nil,
                notesPerSecond: 0,
                beatsPerMinute: 72,
                intensity: .steady
            )
        }
        let averageInterval = positiveIntervals.reduce(0, +) / Double(positiveIntervals.count)
        let notesPerSecond = averageInterval > 0 ? 1 / averageInterval : 0
        let beatsPerMinute = max(48, min(Int((notesPerSecond * 60).rounded()), 220))

        let intensity: TypingIntensity
        switch notesPerSecond {
        case ..<1.25:
            intensity = .relaxed
        case ..<2.8:
            intensity = .steady
        case ..<4.8:
            intensity = .energetic
        default:
            intensity = .frantic
        }

        return TypingTempoSnapshot(
            averageInterval: averageInterval,
            notesPerSecond: notesPerSecond,
            beatsPerMinute: beatsPerMinute,
            intensity: intensity
        )
    }

    mutating func reset() {
        timestamps.removeAll(keepingCapacity: true)
    }
}

struct TypingDashboardSnapshot: Equatable {
    let wordsPerMinute: Int
    let topKeys: [AdaptiveKeyStat]
}

struct TypingDashboardTracker {
    private struct DashboardEvent {
        let timestamp: Date
        let delta: Int
    }

    private var recentEvents: [DashboardEvent] = []
    private var sessionLetterCounts: [String: Int] = [:]
    private let rollingWindow: TimeInterval = 18
    private let minimumMeasurementWindow: TimeInterval = 3

    var topKeyStats: [AdaptiveKeyStat] {
        rankedKeys(prefix: 8)
    }

    mutating func register(symbol: KeyboardSymbol, at timestamp: Date) -> TypingDashboardSnapshot {
        if let heatKeyID = symbol.dashboardHeatKeyID {
            sessionLetterCounts[heatKeyID, default: 0] += 1
        }

        let delta = symbol.dashboardCharacterDelta
        if delta != 0 {
            recentEvents.append(DashboardEvent(timestamp: timestamp, delta: delta))
        }

        prune(before: timestamp.addingTimeInterval(-rollingWindow))
        return snapshot()
    }

    private mutating func prune(before cutoff: Date) {
        recentEvents.removeAll { $0.timestamp < cutoff }
    }

    private func snapshot() -> TypingDashboardSnapshot {
        let charactersTyped = max(0, recentEvents.reduce(0) { $0 + $1.delta })
        let measuredDuration: TimeInterval

        if let first = recentEvents.first?.timestamp,
           let last = recentEvents.last?.timestamp {
            measuredDuration = max(minimumMeasurementWindow, last.timeIntervalSince(first))
        } else {
            measuredDuration = minimumMeasurementWindow
        }

        let wordsPerMinute: Int
        if charactersTyped == 0 {
            wordsPerMinute = 0
        } else {
            let wordsTyped = Double(charactersTyped) / 5.0
            let minutes = measuredDuration / 60.0
            wordsPerMinute = max(0, min(Int((wordsTyped / minutes).rounded()), 220))
        }

        return TypingDashboardSnapshot(
            wordsPerMinute: wordsPerMinute,
            topKeys: rankedKeys(prefix: 8)
        )
    }

    private func rankedKeys(prefix limit: Int) -> [AdaptiveKeyStat] {
        Array(
            sessionLetterCounts
                .map { key, count in
                    AdaptiveKeyStat(
                        id: key,
                        label: key.uppercased(),
                        count: count
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.count != rhs.count {
                        return lhs.count > rhs.count
                    }

                    return lhs.label < rhs.label
                }
                .prefix(limit)
        )
    }
}

struct AdaptiveKeyUsageSnapshot: Equatable {
    let rank: Int?
    let count: Int
    let topKeys: [AdaptiveKeyStat]
}

private struct TypingExpressionTracker {
    private var history: [KeyboardSymbol] = []
    private let maxHistory = 72

    mutating func register(symbol: KeyboardSymbol) -> TypingExpressionSnapshot {
        history.append(symbol)

        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }

        return snapshot()
    }

    func preview(after symbol: KeyboardSymbol) -> TypingExpressionSnapshot {
        var copy = self
        return copy.register(symbol: symbol)
    }

    mutating func reset() {
        history.removeAll(keepingCapacity: true)
    }

    private func snapshot() -> TypingExpressionSnapshot {
        let recentText = renderedRecentText()
        let words = recentWords(in: recentText)
        let deletePressure = deletePressure()
        let positiveScore = wordScore(for: words, lexicon: Self.positiveLexicon) + joyPunctuationScore()
        let negativeScore = wordScore(for: words, lexicon: Self.negativeLexicon) + deletePressure
        let tensionScore = wordScore(for: words, lexicon: Self.tenseLexicon) + punctuationTensionScore() + (deletePressure * 0.8)
        let localVibe = LocalTypingVibeAnalyzer().analyzeLocally(text: recentText)
        let fallbackMood = inferredMood(
            positiveScore: positiveScore,
            negativeScore: negativeScore,
            tensionScore: tensionScore
        )
        let textMood = localVibe.textMood == .neutral ? fallbackMood : localVibe.textMood

        return TypingExpressionSnapshot(
            textMood: textMood,
            recentText: recentText,
            positiveScore: positiveScore,
            negativeScore: negativeScore,
            tensionScore: tensionScore,
            vibeSource: .local,
            vibeConfidence: localVibe.confidence,
            vibeEnergy: localVibe.energy,
            vibeValence: localVibe.valence,
            vibeResponseIntensity: .balanced
        )
    }

    private func renderedRecentText() -> String {
        var characters: [Character] = []

        for symbol in history {
            switch symbol {
            case .letter(let character),
                 .number(let character),
                 .punctuation(let character):
                characters.append(character)
            case .space, .tab, .returnKey:
                if characters.last != " " {
                    characters.append(" ")
                }
            case .delete:
                if !characters.isEmpty {
                    characters.removeLast()
                }
            case .escape, .modifier, .arrow, .unknown:
                continue
            }
        }

        return String(characters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func recentWords(in text: String) -> [String] {
        Array(
            text
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map { String($0).lowercased() }
                .suffix(6)
        )
    }

    private func wordScore(for words: [String], lexicon: [String: Double]) -> Double {
        words.reduce(0) { partialResult, word in
            partialResult + (lexicon[word] ?? 0)
        }
    }

    private func joyPunctuationScore() -> Double {
        let exclamationCount = history.reduce(into: 0) { count, symbol in
            if case .punctuation("!") = symbol {
                count += 1
            }
        }

        return min(Double(exclamationCount) * 0.18, 0.54)
    }

    private func deletePressure() -> Double {
        let deleteCount = history.reduce(into: 0) { count, symbol in
            if case .delete = symbol {
                count += 1
            }
        }

        return min(Double(deleteCount) * 0.32, 1.28)
    }

    private func punctuationTensionScore() -> Double {
        history.reduce(0) { score, symbol in
            switch symbol {
            case .punctuation("?"):
                score + 0.42
            case .punctuation("!"):
                score + 0.18
            case .punctuation(":"),
                 .punctuation(";"):
                score + 0.08
            default:
                score
            }
        }
    }

    private func inferredMood(
        positiveScore: Double,
        negativeScore: Double,
        tensionScore: Double
    ) -> TypingTextMood {
        if negativeScore >= max(1.55, positiveScore + 0.4) {
            return .angry
        }

        if positiveScore >= max(1.15, negativeScore + 0.25),
           positiveScore >= tensionScore * 0.72 {
            return .joyful
        }

        if tensionScore >= 1.05 || negativeScore >= 0.95 {
            return negativeScore >= 1.35 ? .angry : .tense
        }

        return .neutral
    }

    private static let positiveLexicon: [String: Double] = [
        "awesome": 1.5,
        "cool": 1.1,
        "fun": 1.0,
        "good": 1.1,
        "great": 1.3,
        "haha": 1.4,
        "happy": 1.4,
        "love": 1.6,
        "lol": 1.2,
        "nice": 1.0,
        "perfect": 1.5,
        "sweet": 1.0,
        "wow": 1.1,
        "yay": 1.4,
        "yes": 0.8
    ]

    private static let negativeLexicon: [String: Double] = [
        "angry": 1.5,
        "annoying": 1.6,
        "awful": 1.6,
        "bad": 1.1,
        "broken": 1.1,
        "damn": 1.2,
        "fuck": 1.7,
        "hate": 1.6,
        "mad": 1.3,
        "no": 0.8,
        "shit": 1.5,
        "stop": 0.9,
        "stupid": 1.5,
        "ugh": 1.2
    ]

    private static let tenseLexicon: [String: Double] = [
        "cant": 1.0,
        "could": 0.6,
        "dont": 1.0,
        "fix": 0.7,
        "issue": 0.9,
        "maybe": 0.7,
        "need": 0.5,
        "not": 0.9,
        "problem": 1.1,
        "should": 0.7,
        "wait": 0.7,
        "what": 0.6,
        "weird": 0.8,
        "why": 1.0,
        "wrong": 1.0
    ]
}

private struct TypingBurstTracker {
    private static let idleResetInterval: TimeInterval = 3

    private var lastTimestamp: Date?

    mutating func register(at timestamp: Date) -> Bool {
        defer { lastTimestamp = timestamp }

        guard let lastTimestamp else {
            return true
        }

        return timestamp.timeIntervalSince(lastTimestamp) >= Self.idleResetInterval
    }

    func isActive(at timestamp: Date) -> Bool {
        guard let lastTimestamp else {
            return false
        }

        return timestamp.timeIntervalSince(lastTimestamp) < Self.idleResetInterval
    }

    mutating func reset() {
        lastTimestamp = nil
    }
}

private struct TypingBurstPerformance: Equatable {
    let textMood: TypingTextMood
    let performanceStyle: KeyboardPerformanceStyle
}

private struct TypingPerformanceBurstLock {
    private var lockedPerformance: TypingBurstPerformance?
    private var meaningfulEventCount = 0

    mutating func resolve(
        for symbol: KeyboardSymbol,
        instrument: KeyboardInstrument,
        tempo: TypingTempoSnapshot,
        expressionSnapshot: TypingExpressionSnapshot
    ) -> TypingBurstPerformance {
        if symbol.contributesToBurstIdentity {
            meaningfulEventCount += 1
        }

        if let lockedPerformance {
            return lockedPerformance
        }

        let livePerformance = TypingBurstPerformance(
            textMood: expressionSnapshot.textMood,
            performanceStyle: KeyboardPerformanceStyle.forInstrument(
                instrument,
                tempo: tempo,
                expression: expressionSnapshot
            )
        )

        if shouldLock(after: symbol) {
            lockedPerformance = livePerformance
        }

        return livePerformance
    }

    func preview(
        for symbol: KeyboardSymbol,
        instrument: KeyboardInstrument,
        tempo: TypingTempoSnapshot,
        expressionSnapshot: TypingExpressionSnapshot,
        prefersLockedBurst: Bool
    ) -> TypingBurstPerformance {
        if prefersLockedBurst, let lockedPerformance {
            return lockedPerformance
        }

        return TypingBurstPerformance(
            textMood: expressionSnapshot.textMood,
            performanceStyle: KeyboardPerformanceStyle.forInstrument(
                instrument,
                tempo: tempo,
                expression: expressionSnapshot
            )
        )
    }

    mutating func reset() {
        lockedPerformance = nil
        meaningfulEventCount = 0
    }

    private func shouldLock(after symbol: KeyboardSymbol) -> Bool {
        meaningfulEventCount >= 4 || (symbol.isBurstBoundary && meaningfulEventCount >= 2)
    }
}

struct AdaptiveKeyStat: Equatable {
    let id: String
    let label: String
    let count: Int
}

private struct AdaptiveKeyLearningProfile {
    private static let defaultsKey = "keyboardMusic.adaptiveLetterUsage.v1"

    private var counts: [String: Int]
    private let defaults: UserDefaults?

    init(persistentLearning: Bool) {
        defaults = persistentLearning ? .standard : nil
        counts = (defaults?.dictionary(forKey: Self.defaultsKey) ?? [:]).reduce(into: [:]) { partialResult, element in
            if let count = element.value as? Int {
                partialResult[element.key] = count
            }
        }
    }

    var topKeysSummary: String {
        let top = Array(rankedKeys.prefix(5))
        guard !top.isEmpty else {
            return "Learning your letter habits."
        }

        return top
            .map { "\($0.label)\($0.count)" }
            .joined(separator: " · ")
    }

    var topKeyStats: [AdaptiveKeyStat] {
        Array(rankedKeys.prefix(8))
    }

    var defaultDescription: String {
        "Frequent letters get the home/open/lift tones. Rare letters become color and tension."
    }

    mutating func register(symbol: KeyboardSymbol) -> AdaptiveKeyUsageSnapshot {
        if let learnedKeyID = symbol.learnedKeyID {
            counts[learnedKeyID, default: 0] += 1
            persistIfNeeded()
        }

        return snapshot(for: symbol)
    }

    func snapshot(for symbol: KeyboardSymbol) -> AdaptiveKeyUsageSnapshot {
        let topKeys = Array(rankedKeys.prefix(5))
        let rank = symbol.learnedKeyID.flatMap { learnedKeyID in
            rankedKeys.firstIndex { $0.id == learnedKeyID }
        }
        let count = symbol.learnedKeyID.flatMap { counts[$0] } ?? 0
        return AdaptiveKeyUsageSnapshot(rank: rank, count: count, topKeys: topKeys)
    }

    func description(for symbol: KeyboardSymbol, snapshot: AdaptiveKeyUsageSnapshot) -> String {
        guard let label = symbol.learnedKeyLabel,
              let rank = snapshot.rank else {
            return defaultDescription
        }

        let family = AdaptiveNoteFamily.family(forRank: rank)
        return "\(label) is learned as your #\(rank + 1) letter, so it leans on \(family.displayName.lowercased()) tones."
    }

    private var rankedKeys: [AdaptiveKeyStat] {
        counts
            .map { key, count in
                AdaptiveKeyStat(
                    id: key,
                    label: key.uppercased(),
                    count: count
                )
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }

                return lhs.label < rhs.label
            }
    }

    private func persistIfNeeded() {
        defaults?.set(counts, forKey: Self.defaultsKey)
    }
}

enum KeyboardInputTranslator {
    static func input(for event: NSEvent, source: KeyboardInputSource = .localApp, timestamp: Date = Date()) -> KeyboardInput? {
        guard KeyboardEventFilter.shouldPlay(for: event) else { return nil }

        return KeyboardInput(
            symbol: symbol(for: event.keyCode, eventType: event.type, characters: event.charactersIgnoringModifiers),
            keyCode: event.keyCode,
            source: source,
            timestamp: timestamp
        )
    }

    static func input(for type: CGEventType, keyCode: UInt16, source: KeyboardInputSource = .systemWide, timestamp: Date = Date()) -> KeyboardInput? {
        guard KeyboardEventFilter.shouldPlay(for: type, isAutoRepeat: false) else { return nil }

        return KeyboardInput(
            symbol: symbol(for: keyCode, eventType: type, characters: nil),
            keyCode: keyCode,
            source: source,
            timestamp: timestamp
        )
    }

    private static func symbol(
        for keyCode: UInt16,
        eventType: NSEvent.EventType,
        characters: String?
    ) -> KeyboardSymbol {
        if eventType == .flagsChanged, let modifier = modifier(for: keyCode) {
            return .modifier(modifier)
        }

        if let characters {
            let parsedSymbol = symbol(from: characters)
            if parsedSymbol != nil {
                return parsedSymbol!
            }
        }

        return usANSIMap[keyCode] ?? .unknown(keyCode)
    }

    private static func symbol(
        for keyCode: UInt16,
        eventType: CGEventType,
        characters: String?
    ) -> KeyboardSymbol {
        if eventType == .flagsChanged, let modifier = modifier(for: keyCode) {
            return .modifier(modifier)
        }

        if let characters {
            let parsedSymbol = symbol(from: characters)
            if parsedSymbol != nil {
                return parsedSymbol!
            }
        }

        return usANSIMap[keyCode] ?? .unknown(keyCode)
    }

    private static func symbol(from characters: String) -> KeyboardSymbol? {
        guard !characters.isEmpty else { return nil }

        switch characters {
        case " ":
            return .space
        case "\r":
            return .returnKey
        case "\t":
            return .tab
        default:
            guard characters.count == 1, let character = characters.lowercased().first else {
                return nil
            }

            let scalarString = String(character)
            if scalarString.rangeOfCharacter(from: .letters) != nil {
                return .letter(character)
            }

            if scalarString.rangeOfCharacter(from: .decimalDigits) != nil {
                return .number(character)
            }

            return .punctuation(character)
        }
    }

    private static func modifier(for keyCode: UInt16) -> KeyboardModifierKey? {
        switch keyCode {
        case 54, 55:
            .command
        case 56, 60:
            .shift
        case 57:
            .capsLock
        case 58, 61:
            .option
        case 59, 62:
            .control
        case 63:
            .function
        default:
            nil
        }
    }

    private static let usANSIMap: [UInt16: KeyboardSymbol] = [
        0: .letter("a"),
        1: .letter("s"),
        2: .letter("d"),
        3: .letter("f"),
        4: .letter("h"),
        5: .letter("g"),
        6: .letter("z"),
        7: .letter("x"),
        8: .letter("c"),
        9: .letter("v"),
        11: .letter("b"),
        12: .letter("q"),
        13: .letter("w"),
        14: .letter("e"),
        15: .letter("r"),
        16: .letter("y"),
        17: .letter("t"),
        18: .number("1"),
        19: .number("2"),
        20: .number("3"),
        21: .number("4"),
        22: .number("6"),
        23: .number("5"),
        24: .punctuation("="),
        25: .number("9"),
        26: .number("7"),
        27: .punctuation("-"),
        28: .number("8"),
        29: .number("0"),
        30: .punctuation("]"),
        31: .letter("o"),
        32: .letter("u"),
        33: .punctuation("["),
        34: .letter("i"),
        35: .letter("p"),
        36: .returnKey,
        37: .letter("l"),
        38: .letter("j"),
        39: .punctuation("'"),
        40: .letter("k"),
        41: .punctuation(";"),
        42: .punctuation("\\"),
        43: .punctuation(","),
        44: .punctuation("/"),
        45: .letter("n"),
        46: .letter("m"),
        47: .punctuation("."),
        48: .tab,
        49: .space,
        50: .punctuation("`"),
        51: .delete,
        53: .escape,
        123: .arrow(.left),
        124: .arrow(.right),
        125: .arrow(.down),
        126: .arrow(.up)
    ]
}

private enum KeyboardSoundPlanner {
    static func plan(
        for input: KeyboardInput,
        instrument: KeyboardInstrument,
        profile: InstrumentProfileSnapshot,
        tempo: TypingTempoSnapshot,
        textMood: TypingTextMood,
        performanceStyle: KeyboardPerformanceStyle,
        usageSnapshot: AdaptiveKeyUsageSnapshot,
        previousLeadNoteLabel: String?,
        mappingOverride: SoundMapping? = nil,
        expressionSnapshot: TypingExpressionSnapshot
    ) -> SoundTriggerPlan {
        let mapping = mappingOverride ?? mapping(
            for: input,
            instrument: instrument,
            profile: profile,
            tempo: tempo,
            performanceStyle: performanceStyle,
            usageSnapshot: usageSnapshot,
            previousLeadNoteLabel: previousLeadNoteLabel
        )
        let soundID = makeSoundID(
            profile: profile,
            role: mapping.role,
            keyAssetKey: input.symbol.assetKey,
            noteLabel: mapping.noteLabel
        )

        return SoundTriggerPlan(
            instrument: instrument,
            profile: profile,
            role: mapping.role,
            soundID: soundID,
            noteLabel: mapping.noteLabel,
            noteFamilyName: mapping.noteFamilyName,
            keyLabel: input.symbol.label,
            source: input.source,
            tempo: tempo,
            textMood: textMood,
            performanceStyle: performanceStyle,
            sustainPedalEngaged: sustainPedalEngaged(
                for: input.symbol,
                instrument: instrument,
                tempo: tempo,
                performanceStyle: performanceStyle
            ),
            velocity: mapping.velocity(for: tempo, performanceStyle: performanceStyle),
            learnedRank: mapping.learnedRank,
            vibeSource: expressionSnapshot.vibeSource,
            vibeConfidence: expressionSnapshot.vibeConfidence,
            vibeEnergy: expressionSnapshot.vibeEnergy,
            vibeValence: expressionSnapshot.vibeValence,
            vibeResponseIntensity: expressionSnapshot.vibeResponseIntensity
        )
    }

    private static func sustainPedalEngaged(
        for symbol: KeyboardSymbol,
        instrument: KeyboardInstrument,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle
    ) -> Bool {
        guard instrument == .piano else {
            return false
        }

        switch symbol {
        case .delete, .escape, .returnKey, .punctuation:
            return false
        case .modifier, .arrow:
            return false
        case .tab:
            return tempo.intensity == .relaxed && performanceStyle == .mellow
        case .space:
            switch performanceStyle {
            case .mellow, .warm:
                return tempo.intensity == .relaxed || tempo.intensity == .steady
            case .bright:
                return tempo.intensity == .steady && (tempo.averageInterval ?? 0.5) > 0.32
            case .driving, .stormy:
                return false
            }
        case .letter, .number, .unknown:
            switch performanceStyle {
            case .mellow:
                return true
            case .warm:
                return tempo.intensity != .frantic
            case .bright:
                return tempo.intensity == .steady && (tempo.averageInterval ?? 0.5) > 0.28
            case .driving, .stormy:
                return false
            }
        }
    }

    private static func mapping(
        for input: KeyboardInput,
        instrument: KeyboardInstrument,
        profile: InstrumentProfileSnapshot,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        usageSnapshot: AdaptiveKeyUsageSnapshot,
        previousLeadNoteLabel: String?
    ) -> SoundMapping {
        switch input.symbol {
        case .letter(let character):
            let learnedRank = usageSnapshot.rank ?? alphabetIndex(for: character)
            let family = AdaptiveNoteFamily.family(forRank: learnedRank)
            return SoundMapping(
                role: .melody,
                noteLabel: adaptiveNoteLabel(
                    family: family,
                    instrument: instrument,
                    profile: profile,
                    keyCode: input.keyCode,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: family.displayName,
                learnedRank: usageSnapshot.rank
            )
        case .number(let character):
            let index = numberIndex(for: character)
            return SoundMapping(
                role: .accent,
                noteLabel: nearbyPaletteNote(
                    in: profile.accentPalette,
                    preferredIndex: index,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Accent",
                learnedRank: nil
            )
        case .punctuation(let character):
            let index = punctuationIndex(for: character)
            return SoundMapping(
                role: .cadence,
                noteLabel: nearbyPaletteNote(
                    in: profile.accentPalette,
                    preferredIndex: index,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Cadence",
                learnedRank: nil
            )
        case .space:
            return SoundMapping(
                role: .pulse,
                noteLabel: dynamicPulseNote(
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: pulseFamilyName(for: tempo),
                learnedRank: nil
            )
        case .returnKey:
            return SoundMapping(
                role: .cadence,
                noteLabel: nearbyPaletteNote(
                    in: profile.accentPalette,
                    preferredIndex: profile.accentPalette.count - 1,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Cadence",
                learnedRank: nil
            )
        case .delete, .escape:
            return SoundMapping(
                role: .tension,
                noteLabel: profile.tensionNote,
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Tension",
                learnedRank: nil
            )
        case .tab:
            return SoundMapping(
                role: .texture,
                noteLabel: nearbyPaletteNote(
                    in: profile.texturePalette + profile.accentPalette,
                    preferredIndex: 0,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Texture",
                learnedRank: nil
            )
        case .modifier(let modifier):
            let modifierIndex = modifierIndex(for: modifier)
            return SoundMapping(
                role: .texture,
                noteLabel: nearbyPaletteNote(
                    in: profile.texturePalette + profile.accentPalette,
                    preferredIndex: modifierIndex,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Texture",
                learnedRank: nil
            )
        case .arrow(let arrow):
            let arrowIndex = arrowIndex(for: arrow)
            return SoundMapping(
                role: .navigation,
                noteLabel: nearbyPaletteNote(
                    in: profile.melodicPalette,
                    preferredIndex: arrowIndex,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Navigation",
                learnedRank: nil
            )
        case .unknown:
            return SoundMapping(
                role: .accent,
                noteLabel: nearbyPaletteNote(
                    in: profile.accentPalette,
                    preferredIndex: 0,
                    profile: profile,
                    tempo: tempo,
                    performanceStyle: performanceStyle,
                    previousLeadNoteLabel: previousLeadNoteLabel
                ),
                baseVelocity: normalizedVelocity,
                noteFamilyName: "Accent",
                learnedRank: nil
            )
        }
    }

    private static func adaptiveNoteLabel(
        family: AdaptiveNoteFamily,
        instrument: KeyboardInstrument,
        profile: InstrumentProfileSnapshot,
        keyCode: UInt16,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        previousLeadNoteLabel: String?
    ) -> String {
        let candidates: [String]
        switch instrument {
        case .piano:
            candidates = family.noteLabels(for: instrument, performanceStyle: performanceStyle)
        case .loFiKeys:
            candidates = family.noteLabels(in: profile)
        }
        guard !candidates.isEmpty else {
            return profile.melodicPalette.first ?? "C4"
        }

        let anchorMidi = preferredAnchorMidi(
            for: keyCode,
            profile: profile,
            tempo: tempo,
            performanceStyle: performanceStyle
        )
        let previousMidi = previousLeadNoteLabel
            .flatMap { KeyboardNoteFrequency.midiNote(for: $0) }
            .map(Int.init)

        return candidates.min { lhs, rhs in
            noteSelectionScore(
                for: lhs,
                anchorMidi: anchorMidi,
                tempo: tempo,
                performanceStyle: performanceStyle,
                previousMidi: previousMidi
            ) < noteSelectionScore(
                for: rhs,
                anchorMidi: anchorMidi,
                tempo: tempo,
                performanceStyle: performanceStyle,
                previousMidi: previousMidi
            )
        } ?? candidates[0]
    }

    private static func dynamicPulseNote(
        profile: InstrumentProfileSnapshot,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        previousLeadNoteLabel: String?
    ) -> String {
        let palette = profile.supportPalette
        guard let previousLeadNoteLabel,
              let previousMidi = KeyboardNoteFrequency.midiNote(for: previousLeadNoteLabel).map(Int.init) else {
            return defaultPulseNote(
                in: palette,
                performanceStyle: performanceStyle,
                fallback: profile.supportPalette.first ?? profile.melodicPalette.first ?? "C4"
            )
        }

        let sortedPalette = palette.sorted {
            (KeyboardNoteFrequency.midiNote(for: $0).map(Int.init) ?? previousMidi) <
            (KeyboardNoteFrequency.midiNote(for: $1).map(Int.init) ?? previousMidi)
        }

        switch performanceStyle {
        case .mellow:
            return directionalPaletteNote(
                in: sortedPalette,
                previousMidi: previousMidi,
                direction: .down,
                allowSamePitch: true
            ) ?? sortedPalette.first ?? profile.supportPalette.first ?? "C4"
        case .warm:
            return nearestPaletteNote(in: sortedPalette, toMidi: previousMidi) ?? profile.supportPalette.first ?? "C4"
        case .bright:
            return directionalPaletteNote(
                in: sortedPalette,
                previousMidi: previousMidi,
                direction: .up,
                allowSamePitch: true
            ) ?? nearestPaletteNote(in: sortedPalette, toMidi: previousMidi) ?? profile.supportPalette.first ?? "C4"
        case .driving:
            return directionalPaletteNote(
                in: sortedPalette,
                previousMidi: previousMidi,
                direction: .up,
                allowSamePitch: false
            ) ?? nearestPaletteNote(in: sortedPalette, toMidi: previousMidi) ?? profile.supportPalette.first ?? "C4"
        case .stormy:
            return directionalPaletteNote(
                in: sortedPalette,
                previousMidi: previousMidi,
                direction: .down,
                allowSamePitch: false
            ) ?? nearestPaletteNote(in: sortedPalette, toMidi: previousMidi) ?? profile.supportPalette.first ?? "C4"
        }
    }

    private static func pulseFamilyName(for tempo: TypingTempoSnapshot) -> String {
        switch tempo.intensity {
        case .idle, .relaxed:
            "Mellow Pulse"
        case .steady:
            "Phrase Pulse"
        case .energetic, .frantic:
            "Drive Pulse"
        }
    }

    private static func nearbyPaletteNote(
        in palette: [String],
        preferredIndex: Int,
        profile: InstrumentProfileSnapshot,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        previousLeadNoteLabel: String?
    ) -> String {
        guard !palette.isEmpty else {
            return "C4"
        }

        let normalizedIndex = ((preferredIndex % palette.count) + palette.count) % palette.count
        guard let previousLeadNoteLabel,
              let previousMidi = KeyboardNoteFrequency.midiNote(for: previousLeadNoteLabel).map(Int.init) else {
            return palette[normalizedIndex]
        }

        let candidateIndices = orderedUniqueIndices([
            normalizedIndex - 1,
            normalizedIndex,
            normalizedIndex + 1
        ], count: palette.count)
        let candidates = candidateIndices.map { palette[$0] }
        let anchorMidi = KeyboardNoteFrequency.midiNote(for: palette[normalizedIndex]).map(Int.init) ??
            preferredAnchorMidi(
                for: 0,
                profile: profile,
                tempo: tempo,
                performanceStyle: performanceStyle
            )

        return candidates.min { lhs, rhs in
            noteSelectionScore(
                for: lhs,
                anchorMidi: anchorMidi,
                tempo: tempo,
                performanceStyle: performanceStyle,
                previousMidi: previousMidi
            ) < noteSelectionScore(
                for: rhs,
                anchorMidi: anchorMidi,
                tempo: tempo,
                performanceStyle: performanceStyle,
                previousMidi: previousMidi
            )
        } ?? palette[normalizedIndex]
    }

    private static func noteSelectionScore(
        for noteLabel: String,
        anchorMidi: Int,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle,
        previousMidi: Int?
    ) -> Double {
        let midi = KeyboardNoteFrequency.midiNote(for: noteLabel).map(Int.init) ?? anchorMidi
        let anchorDistance = abs(Double(midi - anchorMidi))
        let previousDistance = previousMidi.map { abs(Double(midi - $0)) } ?? 0
        let movement = selectionMovement(for: tempo.intensity, performanceStyle: performanceStyle)
        let repeatPenalty = previousMidi == midi ? movement.repeatPenalty : 0

        if previousMidi == nil {
            return anchorDistance + movement.registerBias(for: midi, anchorMidi: anchorMidi)
        }

        return (previousDistance * movement.previousWeight) +
            (anchorDistance * movement.anchorWeight) +
            repeatPenalty +
            movement.registerBias(for: midi, anchorMidi: anchorMidi)
    }

    private static func selectionMovement(
        for intensity: TypingIntensity,
        performanceStyle: KeyboardPerformanceStyle
    ) -> SelectionMovementProfile {
        switch intensity {
        case .idle, .relaxed:
            SelectionMovementProfile(
                previousWeight: 1.05,
                anchorWeight: 0.45,
                repeatPenalty: 0.18,
                registerPreference: .settle
            ).adjusted(for: performanceStyle)
        case .steady:
            SelectionMovementProfile(
                previousWeight: 0.88,
                anchorWeight: 0.34,
                repeatPenalty: 0.1,
                registerPreference: .neutral
            ).adjusted(for: performanceStyle)
        case .energetic:
            SelectionMovementProfile(
                previousWeight: 0.72,
                anchorWeight: 0.28,
                repeatPenalty: 0.04,
                registerPreference: .lift
            ).adjusted(for: performanceStyle)
        case .frantic:
            SelectionMovementProfile(
                previousWeight: 0.62,
                anchorWeight: 0.24,
                repeatPenalty: 0,
                registerPreference: .lift
            ).adjusted(for: performanceStyle)
        }
    }

    private static func preferredAnchorMidi(
        for keyCode: UInt16,
        profile: InstrumentProfileSnapshot,
        tempo: TypingTempoSnapshot,
        performanceStyle: KeyboardPerformanceStyle
    ) -> Int {
        let baseMidi = profile.anchorBaseMidi + intensityOffset(for: tempo.intensity)
        let column = KeyboardSpatialLayout.column(for: keyCode)
        return baseMidi + profile.registerBias + performanceRegisterOffset(for: performanceStyle) + (column - 5)
    }

    private static func makeSoundID(
        profile: InstrumentProfileSnapshot,
        role: KeyboardSoundRole,
        keyAssetKey: String,
        noteLabel: String
    ) -> String {
        let normalizedNote = noteLabel.lowercased().replacingOccurrences(of: "#", with: "sharp")
        return "\(profile.soundPrefix).\(role.rawValue).\(keyAssetKey).\(normalizedNote)"
    }

    private static func alphabetIndex(for character: Character) -> Int {
        let normalized = String(character).lowercased()
        guard let asciiValue = normalized.unicodeScalars.first?.value else { return 0 }
        return Int(asciiValue) - 97
    }

    private static func numberIndex(for character: Character) -> Int {
        Int(String(character)) ?? 0
    }

    private static func punctuationIndex(for character: Character) -> Int {
        Int(character.unicodeScalars.first?.value ?? 0)
    }

    private static func modifierIndex(for modifier: KeyboardModifierKey) -> Int {
        switch modifier {
        case .command:
            0
        case .shift:
            1
        case .capsLock:
            2
        case .option:
            3
        case .control:
            4
        case .function:
            5
        }
    }

    private static func arrowIndex(for arrow: KeyboardArrowKey) -> Int {
        switch arrow {
        case .left:
            0
        case .right:
            1
        case .up:
            2
        case .down:
            3
        }
    }

    private static func orderedUniqueIndices(_ indices: [Int], count: Int) -> [Int] {
        var seen = Set<Int>()
        return indices.compactMap { index in
            let normalized = ((index % count) + count) % count
            guard seen.insert(normalized).inserted else {
                return nil
            }
            return normalized
        }
    }

    private static func nearestPaletteNote(in palette: [String], toMidi midi: Int) -> String? {
        palette.min { lhs, rhs in
            let lhsMidi = KeyboardNoteFrequency.midiNote(for: lhs).map(Int.init) ?? midi
            let rhsMidi = KeyboardNoteFrequency.midiNote(for: rhs).map(Int.init) ?? midi
            let lhsDistance = abs(lhsMidi - midi)
            let rhsDistance = abs(rhsMidi - midi)

            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }

            return lhs < rhs
        }
    }

    private static func directionalPaletteNote(
        in palette: [String],
        previousMidi: Int,
        direction: MovementDirection,
        allowSamePitch: Bool
    ) -> String? {
        palette.first { noteLabel in
            let midi = KeyboardNoteFrequency.midiNote(for: noteLabel).map(Int.init) ?? previousMidi

            switch direction {
            case .down:
                return allowSamePitch ? midi <= previousMidi : midi < previousMidi
            case .up:
                return allowSamePitch ? midi >= previousMidi : midi > previousMidi
            }
        }
    }

    private static func defaultPulseNote(
        in palette: [String],
        performanceStyle: KeyboardPerformanceStyle,
        fallback: String
    ) -> String {
        guard !palette.isEmpty else { return fallback }

        switch performanceStyle {
        case .mellow:
            return palette[max(0, (palette.count / 2) - 1)]
        case .warm:
            return palette[palette.count / 2]
        case .bright, .driving:
            return palette[min(palette.count - 1, (palette.count / 2) + 1)]
        case .stormy:
            return palette[max(0, (palette.count / 2) - 2)]
        }
    }

    private static func performanceRegisterOffset(for performanceStyle: KeyboardPerformanceStyle) -> Int {
        switch performanceStyle {
        case .mellow:
            return -1
        case .warm:
            return 0
        case .bright:
            return 2
        case .driving:
            return 1
        case .stormy:
            return -1
        }
    }

    private static func intensityOffset(for intensity: TypingIntensity) -> Int {
        switch intensity {
        case .idle, .relaxed:
            return 0
        case .steady:
            return 1
        case .energetic:
            return 2
        case .frantic:
            return 3
        }
    }

    private static let normalizedVelocity = 0.72
}

struct SoundMapping {
    let role: KeyboardSoundRole
    let noteLabel: String
    let baseVelocity: Double
    let noteFamilyName: String
    let learnedRank: Int?

    func velocity(for _: TypingTempoSnapshot, performanceStyle: KeyboardPerformanceStyle) -> Double {
        let styleScale: Double
        switch performanceStyle {
        case .mellow:
            styleScale = 0.86
        case .warm:
            styleScale = 0.94
        case .bright:
            styleScale = 1
        case .driving:
            styleScale = 1.08
        case .stormy:
            styleScale = 1.16
        }

        return min(max(baseVelocity * styleScale, 0.16), 1)
    }
}

private struct SelectionMovementProfile {
    enum RegisterPreference {
        case settle
        case neutral
        case lift
    }

    let previousWeight: Double
    let anchorWeight: Double
    let repeatPenalty: Double
    let registerPreference: RegisterPreference

    func registerBias(for midi: Int, anchorMidi: Int) -> Double {
        let offset = Double(midi - anchorMidi)

        switch registerPreference {
        case .settle:
            return max(offset, 0) * 0.16
        case .neutral:
            return abs(offset) * 0.03
        case .lift:
            return max(-offset, 0) * 0.14
        }
    }

    func adjusted(for performanceStyle: KeyboardPerformanceStyle) -> SelectionMovementProfile {
        switch performanceStyle {
        case .mellow:
            SelectionMovementProfile(
                previousWeight: previousWeight + 0.14,
                anchorWeight: anchorWeight + 0.04,
                repeatPenalty: repeatPenalty * 0.55,
                registerPreference: .settle
            )
        case .warm:
            self
        case .bright:
            SelectionMovementProfile(
                previousWeight: max(previousWeight - 0.06, 0.1),
                anchorWeight: anchorWeight + 0.03,
                repeatPenalty: repeatPenalty * 0.8,
                registerPreference: .lift
            )
        case .driving:
            SelectionMovementProfile(
                previousWeight: max(previousWeight - 0.12, 0.1),
                anchorWeight: max(anchorWeight - 0.02, 0.08),
                repeatPenalty: repeatPenalty * 0.55,
                registerPreference: .lift
            )
        case .stormy:
            SelectionMovementProfile(
                previousWeight: max(previousWeight - 0.04, 0.1),
                anchorWeight: anchorWeight + 0.06,
                repeatPenalty: repeatPenalty * 0.7,
                registerPreference: .settle
            )
        }
    }
}

private enum MovementDirection {
    case down
    case up
}

enum AdaptiveNoteFamily {
    case home
    case open
    case lift
    case warmth
    case color
    case spark
    case tension

    var displayName: String {
        switch self {
        case .home:
            "Home"
        case .open:
            "Open"
        case .lift:
            "Lift"
        case .warmth:
            "Warmth"
        case .color:
            "Color"
        case .spark:
            "Spark"
        case .tension:
            "Tension"
        }
    }

    static func family(forRank rank: Int) -> AdaptiveNoteFamily {
        let order: [AdaptiveNoteFamily] = [
            .home,
            .open,
            .lift,
            .warmth,
            .color,
            .home,
            .open,
            .lift,
            .warmth,
            .color,
            .spark,
            .spark,
            .tension
        ]

        if rank < order.count {
            return order[rank]
        }

        switch rank % 3 {
        case 0:
            return .color
        case 1:
            return .spark
        default:
            return .tension
        }
    }

    func noteLabels(in profile: InstrumentProfileSnapshot) -> [String] {
        let palette = profile.melodicPalette
        guard !palette.isEmpty else {
            return []
        }

        let middleIndex = palette.count / 2
        let lower = Array(palette.prefix(max(1, middleIndex)))
        let upper = Array(palette.suffix(max(1, palette.count - middleIndex)))

        switch self {
        case .home:
            return Array(lower.prefix(3)) + Array(upper.prefix(1))
        case .open:
            return Array(upper.prefix(4))
        case .lift:
            return Array(upper.dropFirst().prefix(4))
        case .warmth:
            return Array(lower.suffix(3)) + Array(upper.prefix(1))
        case .color:
            return Array(lower.suffix(2)) + Array(upper.prefix(2))
        case .spark:
            return Array(upper.suffix(4))
        case .tension:
            return [profile.tensionNote] + Array(upper.prefix(2))
        }
    }

    func noteLabels(for instrument: KeyboardInstrument, performanceStyle: KeyboardPerformanceStyle) -> [String] {
        switch instrument {
        case .piano:
            let base: [String]
            switch self {
            case .home:
                base = ["C4", "E4", "G4", "C5"]
            case .open:
                base = ["G4", "A4", "C5", "E5"]
            case .lift:
                base = ["E4", "G4", "A4", "D5"]
            case .warmth:
                base = ["A3", "C4", "E4", "A4"]
            case .color:
                base = ["D4", "E4", "G4", "A4"]
            case .spark:
                base = ["G4", "A4", "C5", "E5"]
            case .tension:
                base = ["B3", "D4", "E4", "G4"]
            }

            return styledPianoNotes(from: base, family: self, performanceStyle: performanceStyle)
        case .loFiKeys:
            switch self {
            case .home:
                return ["C3", "G3", "C4", "E4"]
            case .open:
                return ["G3", "C4", "D4", "G4"]
            case .lift:
                return ["E3", "E4", "G4", "C4"]
            case .warmth:
                return ["A2", "A3", "E4", "A4"]
            case .color:
                return ["D3", "D4", "F4", "A4"]
            case .spark:
                return ["F3", "F4", "A4", "C5"]
            case .tension:
                return ["B2", "B3", "D4", "G4"]
            }
        }
    }

    private func styledPianoNotes(
        from base: [String],
        family: AdaptiveNoteFamily,
        performanceStyle: KeyboardPerformanceStyle
    ) -> [String] {
        let extras: [String]

        switch performanceStyle {
        case .mellow:
            switch family {
            case .home:
                extras = ["C4", "E4", "G4"]
            case .open:
                extras = ["G4", "A4", "C5"]
            case .lift:
                extras = ["E4", "G4", "A4"]
            case .warmth:
                extras = ["A3", "C4", "D4"]
            case .color:
                extras = ["C4", "D4", "E4"]
            case .spark:
                extras = ["E4", "G4", "A4"]
            case .tension:
                extras = ["B3", "D4", "E4"]
            }
        case .warm:
            extras = []
        case .bright:
            switch family {
            case .home:
                extras = ["E5", "G5"]
            case .open:
                extras = ["E5", "G5", "A5"]
            case .lift:
                extras = ["D5", "E5", "G5"]
            case .warmth:
                extras = ["C5", "E5"]
            case .color:
                extras = ["A4", "C5", "E5"]
            case .spark:
                extras = ["E5", "G5", "A5"]
            case .tension:
                extras = ["D5", "F5"]
            }
        case .driving:
            switch family {
            case .home:
                extras = ["G4", "C5", "E5"]
            case .open:
                extras = ["C5", "E5", "G5"]
            case .lift:
                extras = ["A4", "D5", "G5"]
            case .warmth:
                extras = ["E4", "A4", "C5"]
            case .color:
                extras = ["G4", "A4", "D5"]
            case .spark:
                extras = ["C5", "E5", "G5"]
            case .tension:
                extras = ["D4", "E4", "A4"]
            }
        case .stormy:
            switch family {
            case .home:
                extras = ["A3", "B3", "D4"]
            case .open:
                extras = ["D4", "G4", "B4"]
            case .lift:
                extras = ["D4", "F4", "A4"]
            case .warmth:
                extras = ["G3", "A3", "C4"]
            case .color:
                extras = ["C4", "D4", "F4"]
            case .spark:
                extras = ["D4", "G4", "B4"]
            case .tension:
                extras = ["B3", "D4", "F4", "A4"]
            }
        }

        return orderedUniqueNotes(extras + base)
    }

    private func orderedUniqueNotes(_ notes: [String]) -> [String] {
        var seen = Set<String>()
        return notes.filter { seen.insert($0).inserted }
    }
}

private extension KeyboardSoundRole {
    var shouldInfluenceVoiceLeading: Bool {
        switch self {
        case .melody, .cadence, .accent, .navigation:
            true
        case .pulse, .tension, .texture:
            false
        }
    }
}

private func punctuationLabel(for character: Character) -> String {
    switch character {
    case ".":
        "Period"
    case ",":
        "Comma"
    case "!":
        "Exclamation"
    case "?":
        "Question Mark"
    case ":":
        "Colon"
    case ";":
        "Semicolon"
    case "'":
        "Quote"
    case "\"":
        "Double Quote"
    case "-":
        "Dash"
    case "_":
        "Underscore"
    case "/":
        "Slash"
    case "\\":
        "Backslash"
    case "[":
        "Left Bracket"
    case "]":
        "Right Bracket"
    case "(":
        "Left Parenthesis"
    case ")":
        "Right Parenthesis"
    case "=":
        "Equals"
    case "+":
        "Plus"
    case "`":
        "Backtick"
    default:
        String(character)
    }
}

private func punctuationAssetKey(for character: Character) -> String {
    switch character {
    case ".":
        "period"
    case ",":
        "comma"
    case "!":
        "exclamation"
    case "?":
        "question"
    case ":":
        "colon"
    case ";":
        "semicolon"
    case "'":
        "quote"
    case "\"":
        "double-quote"
    case "-":
        "dash"
    case "_":
        "underscore"
    case "/":
        "slash"
    case "\\":
        "backslash"
    case "[":
        "left-bracket"
    case "]":
        "right-bracket"
    case "(":
        "left-parenthesis"
    case ")":
        "right-parenthesis"
    case "=":
        "equals"
    case "+":
        "plus"
    case "`":
        "backtick"
    default:
        "symbol-\(Int(character.unicodeScalars.first?.value ?? 0))"
    }
}
