//
//  TypingVibe.swift
//  NoisyKeys
//
//  Created by Codex on 4/20/26.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum VibeAnalysisMode: String, CaseIterable, Identifiable, Equatable {
    case automatic
    case localOnly

    var id: Self { self }

    var displayName: String {
        switch self {
        case .automatic:
            "Automatic"
        case .localOnly:
            "Local Only"
        }
    }
}

enum TypingVibeResponseIntensity: String, CaseIterable, Identifiable, Equatable {
    case subtle
    case balanced
    case dramatic

    var id: Self { self }

    var displayName: String {
        switch self {
        case .subtle:
            "Subtle"
        case .balanced:
            "Balanced"
        case .dramatic:
            "Dramatic"
        }
    }

    var confirmationCount: Int {
        switch self {
        case .subtle:
            3
        case .balanced:
            2
        case .dramatic:
            1
        }
    }
}

struct TypingVibeConfiguration: Equatable {
    var isEnabled: Bool
    var mode: VibeAnalysisMode
    var responseIntensity: TypingVibeResponseIntensity

    static let defaultValue = TypingVibeConfiguration(
        isEnabled: true,
        mode: .automatic,
        responseIntensity: .balanced
    )
}

enum TypingVibeSource: String, Equatable {
    case disabled
    case local
    case appleIntelligence

    var displayName: String {
        switch self {
        case .disabled:
            "Off"
        case .local:
            "Local vibe engine"
        case .appleIntelligence:
            "Apple Intelligence"
        }
    }
}

enum AppleIntelligenceAvailability: Equatable {
    case available
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unsupportedOS
    case unsupportedSDK
    case unavailable

    var fallbackReason: String {
        switch self {
        case .available:
            "Apple Intelligence ready"
        case .deviceNotEligible:
            "device not eligible"
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence off in Settings"
        case .modelNotReady:
            "model not ready"
        case .unsupportedOS:
            "macOS 26 required"
        case .unsupportedSDK:
            "Foundation Models SDK unavailable"
        case .unavailable:
            "Apple Intelligence unavailable"
        }
    }
}

struct VibeAnalysisResult: Equatable {
    let textMood: TypingTextMood
    let source: TypingVibeSource
    let confidence: Double
    let energy: Double
    let valence: Double

    static let neutralLocal = VibeAnalysisResult(
        textMood: .neutral,
        source: .local,
        confidence: 0.35,
        energy: 0.25,
        valence: 0
    )
}

struct TypingVibeSnapshot: Equatable {
    let textMood: TypingTextMood
    let source: TypingVibeSource
    let confidence: Double
    let energy: Double
    let valence: Double
    let responseIntensity: TypingVibeResponseIntensity
    let statusDescription: String
    let isEnabled: Bool

    static func disabled(responseIntensity: TypingVibeResponseIntensity = .balanced) -> TypingVibeSnapshot {
        TypingVibeSnapshot(
            textMood: .neutral,
            source: .disabled,
            confidence: 0,
            energy: 0,
            valence: 0,
            responseIntensity: responseIntensity,
            statusDescription: "Vibe detection off",
            isEnabled: false
        )
    }

    static func localFallback(
        result: VibeAnalysisResult,
        configuration: TypingVibeConfiguration,
        availability: AppleIntelligenceAvailability
    ) -> TypingVibeSnapshot {
        let status: String
        switch configuration.mode {
        case .automatic:
            if availability == .available {
                status = "Apple Intelligence ready"
            } else {
                status = "Local vibe engine · \(availability.fallbackReason)"
            }
        case .localOnly:
            status = "Local vibe engine"
        }

        return TypingVibeSnapshot(
            textMood: result.textMood,
            source: .local,
            confidence: result.confidence,
            energy: result.energy,
            valence: result.valence,
            responseIntensity: configuration.responseIntensity,
            statusDescription: status,
            isEnabled: configuration.isEnabled
        )
    }

    static func apple(
        result: VibeAnalysisResult,
        configuration: TypingVibeConfiguration
    ) -> TypingVibeSnapshot {
        TypingVibeSnapshot(
            textMood: result.textMood,
            source: .appleIntelligence,
            confidence: result.confidence,
            energy: result.energy,
            valence: result.valence,
            responseIntensity: configuration.responseIntensity,
            statusDescription: "Apple Intelligence active",
            isEnabled: configuration.isEnabled
        )
    }
}

struct TypingVibeAnalysisRequest: Equatable {
    let id: Int
    let text: String
    let debounceInterval: TimeInterval
}

struct TypingVibeCoordinatorUpdate: Equatable {
    let snapshot: TypingVibeSnapshot
    let analysisRequest: TypingVibeAnalysisRequest?
}

protocol VibeAnalyzer {
    var availability: AppleIntelligenceAvailability { get }
    func analyze(text: String) async -> VibeAnalysisResult?
}

struct TypingVibeCoordinator {
    private var configuration: TypingVibeConfiguration
    private var textBuffer = TypingVibeTextBuffer()
    private var smoother = TypingVibeSmoother()
    private var latestSnapshot: TypingVibeSnapshot
    private var lastScheduledText = ""
    private var requestCounter = 0
    private var meaningfulEventsSinceRequest = 0
    private let localAnalyzer = LocalTypingVibeAnalyzer()
    private let minimumExternalTextLength = 8
    private let minimumExternalEventSpacing = 12
    private let externalDebounceInterval: TimeInterval = 0.55

    init(configuration: TypingVibeConfiguration = .defaultValue) {
        self.configuration = configuration
        latestSnapshot = configuration.isEnabled
            ? TypingVibeSnapshot.localFallback(
                result: .neutralLocal,
                configuration: configuration,
                availability: .unavailable
            )
            : .disabled(responseIntensity: configuration.responseIntensity)
    }

    var currentSnapshot: TypingVibeSnapshot {
        latestSnapshot
    }

    mutating func updateConfiguration(
        _ newConfiguration: TypingVibeConfiguration,
        appleAvailability: AppleIntelligenceAvailability
    ) -> TypingVibeSnapshot {
        configuration = newConfiguration

        if !newConfiguration.isEnabled {
            textBuffer.reset()
            smoother.reset()
            lastScheduledText = ""
            meaningfulEventsSinceRequest = 0
            latestSnapshot = .disabled(responseIntensity: newConfiguration.responseIntensity)
            return latestSnapshot
        }

        let result = smoother.update(
            with: .neutralLocal,
            responseIntensity: newConfiguration.responseIntensity
        )
        latestSnapshot = TypingVibeSnapshot.localFallback(
            result: result,
            configuration: newConfiguration,
            availability: appleAvailability
        )
        return latestSnapshot
    }

    mutating func register(
        symbol: KeyboardSymbol,
        at timestamp: Date,
        appleAvailability: AppleIntelligenceAvailability
    ) -> TypingVibeCoordinatorUpdate {
        guard configuration.isEnabled else {
            latestSnapshot = .disabled(responseIntensity: configuration.responseIntensity)
            return TypingVibeCoordinatorUpdate(snapshot: latestSnapshot, analysisRequest: nil)
        }

        let didChangeText = textBuffer.register(symbol: symbol, at: timestamp)
        if didChangeText {
            meaningfulEventsSinceRequest += 1
        }

        let localResult = localAnalyzer.analyzeLocally(text: textBuffer.text)
        let smoothedResult = smoother.update(
            with: localResult,
            responseIntensity: configuration.responseIntensity
        )
        latestSnapshot = TypingVibeSnapshot.localFallback(
            result: smoothedResult,
            configuration: configuration,
            availability: appleAvailability
        )

        let request = makeAnalysisRequest(
            after: symbol,
            text: textBuffer.text,
            appleAvailability: appleAvailability
        )

        return TypingVibeCoordinatorUpdate(snapshot: latestSnapshot, analysisRequest: request)
    }

    mutating func applyExternalResult(
        _ result: VibeAnalysisResult,
        requestID: Int
    ) -> TypingVibeSnapshot? {
        guard configuration.isEnabled else { return nil }
        guard requestID == requestCounter else { return nil }

        let smoothedResult = smoother.update(
            with: result,
            responseIntensity: configuration.responseIntensity
        )
        latestSnapshot = TypingVibeSnapshot.apple(
            result: smoothedResult,
            configuration: configuration
        )
        return latestSnapshot
    }

    private mutating func makeAnalysisRequest(
        after symbol: KeyboardSymbol,
        text: String,
        appleAvailability: AppleIntelligenceAvailability
    ) -> TypingVibeAnalysisRequest? {
        guard configuration.mode == .automatic else { return nil }
        guard appleAvailability == .available else { return nil }
        guard text.count >= minimumExternalTextLength else { return nil }
        guard text != lastScheduledText else { return nil }

        let shouldRequest: Bool
        switch symbol {
        case .punctuation, .returnKey:
            shouldRequest = true
        case .space, .tab:
            shouldRequest = meaningfulEventsSinceRequest >= 4
        case .letter, .number:
            shouldRequest = meaningfulEventsSinceRequest >= minimumExternalEventSpacing
        case .delete, .escape, .modifier, .arrow, .unknown:
            shouldRequest = false
        }

        guard shouldRequest else { return nil }

        requestCounter += 1
        lastScheduledText = text
        meaningfulEventsSinceRequest = 0

        return TypingVibeAnalysisRequest(
            id: requestCounter,
            text: text,
            debounceInterval: externalDebounceInterval
        )
    }
}

private struct TypingVibeTextBuffer {
    private(set) var text = ""
    private var lastTimestamp: Date?
    private let maxCharacters = 280
    private let idleClearInterval: TimeInterval = 12

    mutating func register(symbol: KeyboardSymbol, at timestamp: Date) -> Bool {
        if let lastTimestamp,
           timestamp.timeIntervalSince(lastTimestamp) > idleClearInterval {
            reset()
        }
        lastTimestamp = timestamp

        let previousText = text

        switch symbol {
        case .letter(let character),
             .number(let character),
             .punctuation(let character):
            text.append(character)
        case .space, .tab, .returnKey:
            if text.last != " " {
                text.append(" ")
            }
        case .delete:
            if !text.isEmpty {
                text.removeLast()
            }
        case .escape, .modifier, .arrow, .unknown:
            break
        }

        if text.count > maxCharacters {
            text = String(text.suffix(maxCharacters))
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text != previousText
    }

    mutating func reset() {
        text = ""
        lastTimestamp = nil
    }
}

private struct TypingVibeSmoother {
    private var current = VibeAnalysisResult.neutralLocal
    private var pendingMood: TypingTextMood?
    private var pendingCount = 0

    mutating func update(
        with candidate: VibeAnalysisResult,
        responseIntensity: TypingVibeResponseIntensity
    ) -> VibeAnalysisResult {
        guard candidate.confidence >= 0.34 else {
            return current
        }

        if current.textMood == .neutral || candidate.textMood == current.textMood {
            pendingMood = nil
            pendingCount = 0
            current = blended(current, candidate, keepsMood: candidate.textMood)
            return current
        }

        if candidate.textMood == .neutral {
            pendingMood = nil
            pendingCount = 0
            current = blended(current, candidate, keepsMood: current.textMood)
            return current
        }

        if pendingMood == candidate.textMood {
            pendingCount += 1
        } else {
            pendingMood = candidate.textMood
            pendingCount = 1
        }

        let requiredConfirmations = candidate.confidence >= 0.86
            ? max(1, responseIntensity.confirmationCount - 1)
            : responseIntensity.confirmationCount

        guard pendingCount >= requiredConfirmations else {
            current = blended(current, candidate, keepsMood: current.textMood)
            return current
        }

        pendingMood = nil
        pendingCount = 0
        current = blended(current, candidate, keepsMood: candidate.textMood)
        return current
    }

    mutating func reset() {
        current = .neutralLocal
        pendingMood = nil
        pendingCount = 0
    }

    private func blended(
        _ current: VibeAnalysisResult,
        _ candidate: VibeAnalysisResult,
        keepsMood mood: TypingTextMood
    ) -> VibeAnalysisResult {
        let blend = 0.46
        return VibeAnalysisResult(
            textMood: mood,
            source: candidate.source,
            confidence: clamp((current.confidence * (1 - blend)) + (candidate.confidence * blend)),
            energy: clamp((current.energy * (1 - blend)) + (candidate.energy * blend)),
            valence: clampSigned((current.valence * (1 - blend)) + (candidate.valence * blend))
        )
    }
}

struct LocalTypingVibeAnalyzer: VibeAnalyzer {
    var availability: AppleIntelligenceAvailability { .available }

    func analyze(text: String) async -> VibeAnalysisResult? {
        analyzeLocally(text: text)
    }

    func analyzeLocally(text: String) -> VibeAnalysisResult {
        let normalizedText = text.lowercased()
        let words = Self.words(in: normalizedText)

        guard !words.isEmpty || normalizedText.contains("!") || normalizedText.contains("?") else {
            return .neutralLocal
        }

        var scores = TypingVibeScores()
        for word in words.suffix(24) {
            scores.joy += Self.score(word, in: Self.joyLexicon)
            scores.playful += Self.score(word, in: Self.playfulLexicon)
            scores.tender += Self.score(word, in: Self.tenderLexicon)
            scores.focused += Self.score(word, in: Self.focusLexicon)
            scores.sad += Self.score(word, in: Self.sadLexicon)
            scores.angry += Self.score(word, in: Self.angryLexicon)
            scores.tense += Self.score(word, in: Self.tenseLexicon)
        }

        let exclamationCount = normalizedText.filter { $0 == "!" }.count
        let questionCount = normalizedText.filter { $0 == "?" }.count
        scores.joy += min(Double(exclamationCount) * 0.18, 0.54)
        scores.playful += min(Double(exclamationCount) * 0.1, 0.3)
        scores.tense += min(Double(questionCount) * 0.34, 1.02)
        if normalizedText.contains("!!") {
            scores.angry += 0.28
        }
        if normalizedText.contains("...") {
            scores.sad += 0.42
            scores.tender += 0.12
        }

        return result(for: scores)
    }

    private func result(for scores: TypingVibeScores) -> VibeAnalysisResult {
        let ranked: [(TypingTextMood, Double, Double, Double)] = [
            (.angry, scores.angry, -0.95, 0.9),
            (.sad, scores.sad, -0.72, 0.28),
            (.playful, scores.playful, 0.84, 0.76),
            (.tender, scores.tender, 0.52, 0.22),
            (.joyful, scores.joy, 0.78, 0.66),
            (.focused, scores.focused, 0.12, 0.46),
            (.tense, scores.tense, -0.28, 0.72)
        ]

        guard let winner = ranked.max(by: { $0.1 < $1.1 }),
              winner.1 >= 0.82 else {
            return VibeAnalysisResult(
                textMood: .neutral,
                source: .local,
                confidence: 0.42,
                energy: min(max(scores.energyFloor, 0.2), 0.44),
                valence: 0
            )
        }

        let runnerUp = ranked
            .filter { $0.0 != winner.0 }
            .map(\.1)
            .max() ?? 0
        let margin = max(winner.1 - runnerUp, 0)
        let confidence = min(0.48 + (winner.1 * 0.16) + (margin * 0.11), 0.94)
        let energy = min(max(winner.3 + (winner.1 * 0.06), 0.16), 0.98)

        return VibeAnalysisResult(
            textMood: winner.0,
            source: .local,
            confidence: confidence,
            energy: energy,
            valence: winner.2
        )
    }

    private static func words(in text: String) -> [String] {
        text
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { String($0) }
    }

    private static func score(_ word: String, in lexicon: [String: Double]) -> Double {
        lexicon[word] ?? 0
    }

    private static let joyLexicon: [String: Double] = [
        "awesome": 1.6, "beautiful": 1.2, "best": 1.1, "cool": 1.0,
        "excellent": 1.5, "good": 1.0, "great": 1.4, "happy": 1.5,
        "love": 1.6, "magic": 1.2, "nice": 1.0, "perfect": 1.6,
        "sweet": 1.0, "wow": 1.2, "yay": 1.6, "yes": 0.9
    ]

    private static let playfulLexicon: [String: Double] = [
        "fun": 1.3, "funny": 1.2, "haha": 1.7, "hehe": 1.4,
        "lol": 1.5, "lmao": 1.6, "party": 1.3, "silly": 1.2,
        "wild": 1.0, "woo": 1.2
    ]

    private static let tenderLexicon: [String: Double] = [
        "care": 1.2, "gentle": 1.4, "grateful": 1.2, "kind": 1.2,
        "miss": 1.0, "soft": 1.3, "thanks": 1.0, "thank": 1.0,
        "warm": 1.0
    ]

    private static let focusLexicon: [String: Double] = [
        "build": 1.0, "code": 0.9, "done": 0.9, "focus": 1.6,
        "implement": 1.2, "plan": 1.0, "review": 0.9, "ship": 1.0,
        "test": 1.0, "work": 0.9
    ]

    private static let sadLexicon: [String: Double] = [
        "alone": 1.2, "cry": 1.5, "hurt": 1.4, "lonely": 1.5,
        "sad": 1.6, "sorry": 1.1, "tired": 1.1, "upset": 1.2
    ]

    private static let angryLexicon: [String: Double] = [
        "angry": 1.6, "awful": 1.5, "bullshit": 1.8, "damn": 1.2,
        "fuck": 1.9, "hate": 1.7, "mad": 1.4, "shit": 1.5,
        "stop": 1.0, "stupid": 1.6, "wtf": 1.7
    ]

    private static let tenseLexicon: [String: Double] = [
        "broken": 1.0, "cant": 1.0, "confused": 1.0, "dont": 0.9,
        "fix": 0.7, "issue": 0.9, "maybe": 0.7, "need": 0.6,
        "not": 0.8, "problem": 1.1, "urgent": 1.2, "wait": 0.7,
        "weird": 0.8, "why": 1.0, "wrong": 1.0
    ]
}

private struct TypingVibeScores {
    var joy = 0.0
    var playful = 0.0
    var tender = 0.0
    var focused = 0.0
    var sad = 0.0
    var angry = 0.0
    var tense = 0.0

    var energyFloor: Double {
        max(joy, playful, focused, angry, tense) * 0.08
    }
}

struct AppleIntelligenceVibeAnalyzer: VibeAnalyzer {
    var availability: AppleIntelligenceAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return FoundationModelVibeClient.availability
        }
        return .unsupportedOS
        #else
        return .unsupportedSDK
        #endif
    }

    func analyze(text: String) async -> VibeAnalysisResult? {
        guard availability == .available else { return nil }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return await FoundationModelVibeClient.analyze(text: text)
        }
        #endif

        return nil
    }
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
private enum FoundationModelVibeClient {
    static var availability: AppleIntelligenceAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            return .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            return .modelNotReady
        case .unavailable:
            return .unavailable
        }
    }

    static func analyze(text: String) async -> VibeAnalysisResult? {
        guard !text.isEmpty else { return nil }

        let instructions = """
        Classify the emotional vibe of typing for a musical keyboard sound engine.
        Return only compact JSON with mood, confidence, valence, and energy.
        mood must be one of: neutral, joyful, playful, tender, focused, tense, angry, sad.
        confidence, valence, and energy must be numbers from -1 to 1 where applicable.
        Do not repeat or summarize the user's text.
        """

        let prompt = """
        Recent typing:
        \(text)
        """

        do {
            let session = LanguageModelSession(
                model: .default,
                instructions: instructions
            )
            let response = try await session.respond(to: prompt)
            return parseResponse(response.content)
        } catch {
            return nil
        }
    }

    private static func parseResponse(_ response: String) -> VibeAnalysisResult? {
        let jsonString = extractJSONObject(from: response)
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        guard let payload = try? JSONDecoder().decode(AppleVibePayload.self, from: data),
              let mood = TypingTextMood(rawValue: payload.mood) else {
            return nil
        }

        return VibeAnalysisResult(
            textMood: mood,
            source: .appleIntelligence,
            confidence: clamp(payload.confidence ?? 0.72),
            energy: clamp(payload.energy ?? 0.5),
            valence: clampSigned(payload.valence ?? 0)
        )
    }

    private static func extractJSONObject(from response: String) -> String {
        guard let start = response.firstIndex(of: "{"),
              let end = response.lastIndex(of: "}"),
              start <= end else {
            return response
        }

        return String(response[start...end])
    }
}

private struct AppleVibePayload: Decodable {
    let mood: String
    let confidence: Double?
    let valence: Double?
    let energy: Double?
}
#endif

private func clamp(_ value: Double) -> Double {
    min(max(value, 0), 1)
}

private func clampSigned(_ value: Double) -> Double {
    min(max(value, -1), 1)
}
