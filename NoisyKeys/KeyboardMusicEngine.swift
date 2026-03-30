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
            "C3"
        case .loFiKeys:
            "C2"
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

struct SoundTriggerPlan: Equatable {
    let instrument: KeyboardInstrument
    let role: KeyboardSoundRole
    let soundID: String
    let noteLabel: String
    let keyLabel: String
    let source: KeyboardInputSource
    let tempo: TypingTempoSnapshot
    let velocity: Double

    var debugSummary: String {
        "\(instrument.displayName) \(role.displayName) \(noteLabel) for \(keyLabel) · \(tempo.summary) · \(source.rawValue)"
    }
}

struct KeyboardMusicEngine {
    var instrument: KeyboardInstrument = .piano

    private var cadenceTracker = TypingCadenceTracker()
    private(set) var lastTempo = TypingTempoSnapshot.idle

    init(instrument: KeyboardInstrument = .piano) {
        self.instrument = instrument
    }

    mutating func plan(for input: KeyboardInput) -> SoundTriggerPlan {
        let tempo = cadenceTracker.register(at: input.timestamp)
        lastTempo = tempo
        return KeyboardSoundPlanner.plan(for: input, instrument: instrument, tempo: tempo)
    }

    func previewPlan(for symbol: KeyboardSymbol, source: KeyboardInputSource = .localApp) -> SoundTriggerPlan {
        let input = KeyboardInput(symbol: symbol, keyCode: 0, source: source, timestamp: Date())
        return KeyboardSoundPlanner.plan(for: input, instrument: instrument, tempo: lastTempo)
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
        case ..<0.9:
            intensity = .relaxed
        case ..<2.2:
            intensity = .steady
        case ..<4.1:
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
        tempo: TypingTempoSnapshot
    ) -> SoundTriggerPlan {
        let mapping = mapping(for: input.symbol, instrument: instrument)
        let soundID = makeSoundID(
            instrument: instrument,
            role: mapping.role,
            keyAssetKey: input.symbol.assetKey,
            noteLabel: mapping.noteLabel
        )

        return SoundTriggerPlan(
            instrument: instrument,
            role: mapping.role,
            soundID: soundID,
            noteLabel: mapping.noteLabel,
            keyLabel: input.symbol.label,
            source: input.source,
            tempo: tempo,
            velocity: mapping.velocity(for: tempo)
        )
    }

    private static func mapping(for symbol: KeyboardSymbol, instrument: KeyboardInstrument) -> SoundMapping {
        switch symbol {
        case .letter(let character):
            let index = alphabetIndex(for: character)
            return SoundMapping(
                role: .melody,
                noteLabel: instrument.melodicPalette[index % instrument.melodicPalette.count],
                baseVelocity: 0.72
            )
        case .number(let character):
            let index = numberIndex(for: character)
            return SoundMapping(
                role: .accent,
                noteLabel: instrument.accentPalette[index % instrument.accentPalette.count],
                baseVelocity: 0.84
            )
        case .punctuation(let character):
            let index = punctuationIndex(for: character)
            return SoundMapping(
                role: .cadence,
                noteLabel: instrument.accentPalette[index % instrument.accentPalette.count],
                baseVelocity: 0.78
            )
        case .space:
            return SoundMapping(role: .pulse, noteLabel: instrument.bassNote, baseVelocity: 0.65)
        case .returnKey:
            return SoundMapping(role: .cadence, noteLabel: instrument.accentPalette.last ?? "C4", baseVelocity: 0.92)
        case .delete, .escape:
            return SoundMapping(role: .tension, noteLabel: instrument.tensionNote, baseVelocity: 0.76)
        case .tab:
            return SoundMapping(role: .texture, noteLabel: instrument.textureNote, baseVelocity: 0.61)
        case .modifier(let modifier):
            let modifierIndex = modifierIndex(for: modifier)
            return SoundMapping(
                role: .texture,
                noteLabel: instrument.accentPalette[modifierIndex % instrument.accentPalette.count],
                baseVelocity: 0.57
            )
        case .arrow(let arrow):
            let arrowIndex = arrowIndex(for: arrow)
            return SoundMapping(
                role: .navigation,
                noteLabel: instrument.melodicPalette[arrowIndex % instrument.melodicPalette.count],
                baseVelocity: 0.58
            )
        case .unknown:
            return SoundMapping(role: .accent, noteLabel: instrument.accentPalette.first ?? "C4", baseVelocity: 0.7)
        }
    }

    private static func makeSoundID(
        instrument: KeyboardInstrument,
        role: KeyboardSoundRole,
        keyAssetKey: String,
        noteLabel: String
    ) -> String {
        let normalizedNote = noteLabel.lowercased().replacingOccurrences(of: "#", with: "sharp")
        return "\(instrument.soundPrefix).\(role.rawValue).\(keyAssetKey).\(normalizedNote)"
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
}

private struct SoundMapping {
    let role: KeyboardSoundRole
    let noteLabel: String
    let baseVelocity: Double

    func velocity(for tempo: TypingTempoSnapshot) -> Double {
        let intensityBoost: Double
        switch tempo.intensity {
        case .idle:
            intensityBoost = 0
        case .relaxed:
            intensityBoost = 0.03
        case .steady:
            intensityBoost = 0.08
        case .energetic:
            intensityBoost = 0.13
        case .frantic:
            intensityBoost = 0.18
        }

        return min(baseVelocity + intensityBoost, 1)
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
