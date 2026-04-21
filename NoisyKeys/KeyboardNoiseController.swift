//
//  KeyboardNoiseController.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation

final class KeyboardNoiseController: ObservableObject {
    static let previewSymbol: KeyboardSymbol = .letter("a")

    @Published var isNoiseEnabled = true
    @Published var hasGlobalAccess = false
    @Published var selectedSoundMode: KeyboardSoundMode = .feltBloom
    @Published var selectedProfileDisplayName = PianoProfileCatalog.defaultProfile.displayName
    @Published var selectedProfileSummary = PianoProfileCatalog.defaultProfile.summary
    @Published var accessMessage = "Checking access..."
    @Published var lastEventDescription = "Waiting for the first clack."
    @Published var lastSoundIdentifier = "Waiting for the first mapped sound."
    @Published var currentTempoDescription = "0 WPM"
    @Published var learnedKeysDescription = "Learning your letter habits."
    @Published var adaptiveMappingDescription = "Frequent letters will settle into the safest note families."
    @Published var performanceDescription = "Warm piano · neutral tone"
    @Published var totalKeyPresses = 0
    @Published var topKeyStats: [AdaptiveKeyStat] = []
    @Published var customPianoSettings = CustomPianoSettings.default
    @Published var isVibeDetectionEnabled = true
    @Published var vibeAnalysisMode: VibeAnalysisMode = .automatic
    @Published var vibeResponseIntensity: TypingVibeResponseIntensity = .balanced
    @Published var vibeStatusDescription = "Local vibe engine"

    private let player = KeyboardSynthPlayer()
    private let playbackQueue = DispatchQueue(label: "NoisyKeys.Playback")
    private let preferences: NoisyKeysUserPreferences
    private let appleVibeAnalyzer: VibeAnalyzer
    private var musicEngine = KeyboardMusicEngine(persistentLearning: true)
    private var vibeCoordinator = TypingVibeCoordinator()
    private var pendingVibeAnalysisWorkItem: DispatchWorkItem?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var isEventTapActive = false
    private var isGlobalMonitorActive = false
    private var hasStarted = false
    private var processedKeyPresses = 0
    private var pendingDisplayState: ControllerDisplayState?
    private var displayRefreshWorkItem: DispatchWorkItem?
    private let displayRefreshInterval: TimeInterval = 0.08

    init(
        preferences: NoisyKeysUserPreferences = .standard,
        appleVibeAnalyzer: VibeAnalyzer = AppleIntelligenceVibeAnalyzer()
    ) {
        self.preferences = preferences
        self.appleVibeAnalyzer = appleVibeAnalyzer

        let storedCustomPianoSettings = preferences.customPianoSettings
        let storedVibeConfiguration = preferences.typingVibeConfiguration
        vibeCoordinator = TypingVibeCoordinator(configuration: storedVibeConfiguration)
        let vibeSnapshot = vibeCoordinator.updateConfiguration(
            storedVibeConfiguration,
            appleAvailability: appleVibeAnalyzer.availability
        )
        musicEngine.setCustomPianoSettings(storedCustomPianoSettings)
        musicEngine.setSoundMode(preferences.selectedSoundMode)
        musicEngine.setTypingVibeSnapshot(vibeSnapshot)

        let selectionState = makeSelectionState()
        isNoiseEnabled = preferences.isNoiseEnabled
        isVibeDetectionEnabled = storedVibeConfiguration.isEnabled
        vibeAnalysisMode = storedVibeConfiguration.mode
        vibeResponseIntensity = storedVibeConfiguration.responseIntensity
        vibeStatusDescription = vibeSnapshot.statusDescription
        selectedSoundMode = selectionState.soundMode
        selectedProfileDisplayName = selectionState.profileDisplayName
        selectedProfileSummary = selectionState.profileSummary
        learnedKeysDescription = selectionState.learnedKeysDescription
        adaptiveMappingDescription = selectionState.adaptiveMappingDescription
        performanceDescription = selectionState.performanceDescription
        topKeyStats = selectionState.topKeyStats
        customPianoSettings = selectionState.customPianoSettings
    }

    deinit {
        stop()
    }

    var monitoringScope: String {
        if isNoiseEnabled {
            return hasGlobalAccess ? "Across your Mac" : "App only"
        }

        return hasGlobalAccess ? "Ready" : "Off"
    }

    var inputMonitoringPath: String {
        "System Settings > Privacy & Security > Input Monitoring"
    }

    var permissionSteps: [String] {
        [
            "Open Noisy Keys from Applications.",
            "Open Privacy & Security > Input Monitoring.",
            "Turn Noisy Keys off and back on if needed.",
            "Return here and click Check Again."
        ]
    }

    func start() {
        guard !hasStarted else { return }

        hasStarted = true
        if !isNoiseEnabled {
            refreshAccessStatus(promptIfNeeded: false)
        }
        setNoiseEnabled(isNoiseEnabled, promptIfNeeded: isNoiseEnabled)
    }

    func setNoiseEnabled(_ isEnabled: Bool, promptIfNeeded: Bool = false) {
        isNoiseEnabled = isEnabled
        preferences.setNoiseEnabled(isEnabled)

        guard hasStarted else { return }

        if isEnabled {
            installLocalMonitorIfNeeded()
            refreshAccessStatus(promptIfNeeded: promptIfNeeded)
        } else {
            removeLocalMonitor()
            disableEventTap()
            removeGlobalMonitor()
            resetPlaybackState()
            accessMessage = hasGlobalAccess
                ? "Sound is off. Turn it on when you want to use Noisy Keys."
                : "Sound is off. Allow access later to use Noisy Keys across your Mac."
        }
    }

    func refreshAccessStatus(promptIfNeeded: Bool = false) {
        let appPath = Bundle.main.bundleURL.standardizedFileURL.path
        let installHint = NoisyKeysInstallLocation.needsApplicationsCopyHint(appPath)
            ? " Move NoisyKeys.app to Applications first; macOS permissions are tied to the exact app copy."
            : ""

        if NoisyKeysInstallLocation.isTemporaryDistributionPath(appPath) {
            disableSystemWideMonitoring()
            hasGlobalAccess = false
            accessMessage = "Move NoisyKeys.app to Applications and reopen it before granting access. Running from the DMG can leave Noisy Keys in app-only mode."
            return
        }

        let hasAccess = promptIfNeeded ? CGRequestListenEventAccess() : CGPreflightListenEventAccess()
        let hasAccessibilityAccess = AXIsProcessTrusted()
        let hasAnySystemWideAccess = hasAccess || hasAccessibilityAccess

        guard isNoiseEnabled else {
            disableSystemWideMonitoring()
            hasGlobalAccess = hasAnySystemWideAccess
            accessMessage = hasAnySystemWideAccess
                ? "Access is ready. Sound is off."
                : "Sound is off. Allow Input Monitoring later to use Noisy Keys across your Mac."
            return
        }

        if hasAccess {
            let didStart = installEventTapIfNeeded()
            hasGlobalAccess = didStart
            accessMessage = didStart
                ? "Keyboard access is on across your Mac."
                : "Input Monitoring is allowed, but the system-wide listener could not start. Quit and reopen Noisy Keys, then click Check Again.\(installHint)"
        } else if hasAccessibilityAccess, installGlobalMonitorIfNeeded() {
            hasGlobalAccess = true
            accessMessage = "Keyboard access is on across your Mac. Input Monitoring is still recommended for the most reliable listener."
        } else {
            disableSystemWideMonitoring()
            hasGlobalAccess = false
            accessMessage = "Allow Noisy Keys in System Settings > Privacy & Security > Input Monitoring.\(installHint) Until then, sound only works while Noisy Keys is in front."
        }
    }

    func checkAccessAgain() {
        refreshAccessStatus(promptIfNeeded: false)
    }

    func openInputMonitoringSettings() {
        if let privacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"),
           NSWorkspace.shared.open(privacyURL) {
            return
        }

        let settingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        NSWorkspace.shared.open(settingsURL)
    }

    func previewSelectedSound() {
        playbackQueue.async { [weak self] in
            guard let self else { return }

            let plan = self.musicEngine.previewPlan(for: Self.previewSymbol)
            self.player.play(plan)
            let displayState = self.makeDisplayState(for: plan, totalKeyPresses: self.processedKeyPresses)
            self.enqueueDisplayState(displayState, immediate: true)
        }
    }

    func setSoundMode(_ mode: KeyboardSoundMode) {
        selectSoundMode(mode)
    }

    func selectSoundMode(_ mode: KeyboardSoundMode, previewSelection: Bool = false) {
        let selectionState = playbackQueue.sync { [self] in
            player.resetPerformanceState()
            musicEngine.setSoundMode(mode)
            return makeSelectionState()
        }
        preferences.setSoundMode(selectionState.soundMode)
        applySelectionState(selectionState)

        if previewSelection {
            previewSelectedSound()
        }
    }

    func setCustomPianoPitch(_ pitch: CustomPianoPitch) {
        var settings = customPianoSettings
        settings.pitch = pitch
        updateCustomPianoSettings(settings)
    }

    func setCustomPianoTone(_ tone: CustomPianoTone) {
        var settings = customPianoSettings
        settings.tone = tone
        updateCustomPianoSettings(settings)
    }

    func setCustomPianoVibe(_ vibe: CustomPianoVibe) {
        var settings = customPianoSettings
        settings.vibe = vibe
        updateCustomPianoSettings(settings)
    }

    func setVibeDetectionEnabled(_ isEnabled: Bool) {
        var configuration = currentVibeConfiguration
        configuration.isEnabled = isEnabled
        updateVibeConfiguration(configuration)
    }

    func setVibeAnalysisMode(_ mode: VibeAnalysisMode) {
        var configuration = currentVibeConfiguration
        configuration.mode = mode
        updateVibeConfiguration(configuration)
    }

    func setVibeResponseIntensity(_ intensity: TypingVibeResponseIntensity) {
        var configuration = currentVibeConfiguration
        configuration.responseIntensity = intensity
        updateVibeConfiguration(configuration)
    }

    private func installLocalMonitorIfNeeded() {
        guard localMonitor == nil else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleLocalEvent(event)
            return event
        }
    }

    private func installEventTapIfNeeded() -> Bool {
        guard CGPreflightListenEventAccess() else { return false }

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isEventTapActive = true
            removeGlobalMonitor()
            return true
        }

        let eventsOfInterest =
            CGEventMask(1 << CGEventType.keyDown.rawValue) |
            CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventsOfInterest,
            callback: Self.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("Noisy Keys could not create the system-wide CGEvent tap.")
            if AXIsProcessTrusted(), installGlobalMonitorIfNeeded() {
                return true
            }
            return false
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        eventTapSource = runLoopSource
        isEventTapActive = true
        removeGlobalMonitor()
        return true
    }

    private func installGlobalMonitorIfNeeded() -> Bool {
        guard AXIsProcessTrusted() else { return false }

        if globalMonitor != nil {
            isGlobalMonitorActive = true
            return true
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleGlobalEvent(event)
        }

        isGlobalMonitorActive = globalMonitor != nil
        if isGlobalMonitorActive {
            disableEventTap()
        }
        return isGlobalMonitorActive
    }

    private func handleLocalEvent(_ event: NSEvent) {
        guard isNoiseEnabled else { return }
        guard !isEventTapActive else { return }
        guard let input = KeyboardInputTranslator.input(for: event, source: .localApp) else { return }

        enqueueProcessing(input, countAsKeyPress: true)
    }

    private func handleGlobalEvent(_ event: NSEvent) {
        guard isNoiseEnabled else { return }
        guard !isEventTapActive else { return }
        guard KeyboardEventFilter.shouldPlay(for: event) else { return }
        guard let input = KeyboardInputTranslator.input(for: event, source: .systemWide) else { return }

        enqueueProcessing(input, countAsKeyPress: true)
    }

    private func stop() {
        removeLocalMonitor()
        tearDownEventTap()
        removeGlobalMonitor()
    }

    private func handleEventTap(type: CGEventType, keyCode: UInt16, isAutoRepeat: Bool) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if isNoiseEnabled, let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                isEventTapActive = true
            }
            return
        }

        guard isNoiseEnabled else { return }
        guard KeyboardEventFilter.shouldPlay(for: type, isAutoRepeat: isAutoRepeat) else { return }
        guard let input = KeyboardInputTranslator.input(for: type, keyCode: keyCode, source: .systemWide) else { return }

        processOnPlaybackQueue(input, countAsKeyPress: true)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let controller = Unmanaged<KeyboardNoiseController>.fromOpaque(userInfo).takeUnretainedValue()
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        controller.playbackQueue.async {
            controller.handleEventTap(type: type, keyCode: keyCode, isAutoRepeat: isAutoRepeat)
        }

        return Unmanaged.passUnretained(event)
    }

    private func removeLocalMonitor() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func removeGlobalMonitor() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        isGlobalMonitorActive = false
    }

    private func disableSystemWideMonitoring() {
        disableEventTap()
        removeGlobalMonitor()
    }

    private func disableEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        isEventTapActive = false
    }

    private func tearDownEventTap() {
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
            self.eventTapSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        isEventTapActive = false
    }

    private func enqueueProcessing(_ input: KeyboardInput, countAsKeyPress: Bool) {
        playbackQueue.async { [weak self] in
            self?.processOnPlaybackQueue(input, countAsKeyPress: countAsKeyPress)
        }
    }

    private func processOnPlaybackQueue(_ input: KeyboardInput, countAsKeyPress: Bool) {
        if countAsKeyPress {
            processedKeyPresses += 1
        }

        let vibeUpdate = vibeCoordinator.register(
            symbol: input.symbol,
            at: input.timestamp,
            appleAvailability: appleVibeAnalyzer.availability
        )
        musicEngine.setTypingVibeSnapshot(vibeUpdate.snapshot)
        if let analysisRequest = vibeUpdate.analysisRequest {
            scheduleVibeAnalysis(analysisRequest)
        }

        let plan = musicEngine.plan(for: input)
        player.play(plan)
        let displayState = makeDisplayState(for: plan, totalKeyPresses: processedKeyPresses)
        enqueueDisplayState(displayState)
    }

    private func resetPlaybackState() {
        playbackQueue.sync {
            player.resetPerformanceState()
        }
    }

    private var currentVibeConfiguration: TypingVibeConfiguration {
        TypingVibeConfiguration(
            isEnabled: isVibeDetectionEnabled,
            mode: vibeAnalysisMode,
            responseIntensity: vibeResponseIntensity
        )
    }

    private func makeSelectionState() -> ControllerSelectionState {
        ControllerSelectionState(
            soundMode: musicEngine.currentSoundMode,
            profileDisplayName: musicEngine.currentProfileDisplayName,
            profileSummary: musicEngine.currentProfileSummary,
            learnedKeysDescription: musicEngine.learnedKeysSummary,
            adaptiveMappingDescription: musicEngine.adaptiveMappingDescription,
            performanceDescription: musicEngine.performanceDescription,
            topKeyStats: musicEngine.topKeyStats,
            customPianoSettings: musicEngine.currentCustomPianoSettings
        )
    }

    private func applySelectionState(_ state: ControllerSelectionState) {
        selectedSoundMode = state.soundMode
        selectedProfileDisplayName = state.profileDisplayName
        selectedProfileSummary = state.profileSummary
        learnedKeysDescription = state.learnedKeysDescription
        adaptiveMappingDescription = state.adaptiveMappingDescription
        performanceDescription = state.performanceDescription
        topKeyStats = state.topKeyStats
        customPianoSettings = state.customPianoSettings
    }

    private func makeDisplayState(for plan: SoundTriggerPlan, totalKeyPresses: Int) -> ControllerDisplayState {
        ControllerDisplayState(
            totalKeyPresses: totalKeyPresses,
            currentTempoDescription: musicEngine.dashboardSpeedSummary,
            lastSoundIdentifier: plan.soundID,
            lastEventDescription: plan.debugSummary,
            learnedKeysDescription: musicEngine.learnedKeysSummary,
            adaptiveMappingDescription: musicEngine.adaptiveMappingDescription,
            performanceDescription: musicEngine.performanceDescription,
            topKeyStats: musicEngine.topKeyStats,
            vibeStatusDescription: vibeCoordinator.currentSnapshot.statusDescription
        )
    }

    private func updateCustomPianoSettings(_ settings: CustomPianoSettings) {
        let selectionState = playbackQueue.sync { [self] in
            musicEngine.setCustomPianoSettings(settings)
            return makeSelectionState()
        }
        preferences.setCustomPianoSettings(selectionState.customPianoSettings)
        applySelectionState(selectionState)
    }

    private func updateVibeConfiguration(_ configuration: TypingVibeConfiguration) {
        let snapshot = playbackQueue.sync { [self] in
            pendingVibeAnalysisWorkItem?.cancel()
            pendingVibeAnalysisWorkItem = nil
            let snapshot = vibeCoordinator.updateConfiguration(
                configuration,
                appleAvailability: appleVibeAnalyzer.availability
            )
            musicEngine.setTypingVibeSnapshot(snapshot)
            return snapshot
        }

        preferences.setTypingVibeConfiguration(configuration)
        isVibeDetectionEnabled = configuration.isEnabled
        vibeAnalysisMode = configuration.mode
        vibeResponseIntensity = configuration.responseIntensity
        vibeStatusDescription = snapshot.statusDescription
    }

    private func scheduleVibeAnalysis(_ request: TypingVibeAnalysisRequest) {
        pendingVibeAnalysisWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }

            let analyzer = self.appleVibeAnalyzer
            Task(priority: .utility) { [weak self] in
                guard let result = await analyzer.analyze(text: request.text) else { return }

                self?.playbackQueue.async { [weak self] in
                    guard let self else { return }
                    guard let snapshot = self.vibeCoordinator.applyExternalResult(
                        result,
                        requestID: request.id
                    ) else {
                        return
                    }

                    self.musicEngine.setTypingVibeSnapshot(snapshot)
                    self.enqueueVibeStatus(snapshot.statusDescription)
                }
            }
        }

        pendingVibeAnalysisWorkItem = workItem
        playbackQueue.asyncAfter(
            deadline: .now() + request.debounceInterval,
            execute: workItem
        )
    }

    private func enqueueVibeStatus(_ statusDescription: String) {
        DispatchQueue.main.async { [weak self] in
            self?.vibeStatusDescription = statusDescription
        }
    }

    private func enqueueDisplayState(_ state: ControllerDisplayState, immediate: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            pendingDisplayState = state

            if immediate {
                flushPendingDisplayState()
                return
            }

            guard displayRefreshWorkItem == nil else { return }

            let workItem = DispatchWorkItem { [weak self] in
                self?.flushPendingDisplayState()
            }
            displayRefreshWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + displayRefreshInterval, execute: workItem)
        }
    }

    private func flushPendingDisplayState() {
        displayRefreshWorkItem?.cancel()
        displayRefreshWorkItem = nil

        guard let state = pendingDisplayState else { return }
        pendingDisplayState = nil

        totalKeyPresses = state.totalKeyPresses
        currentTempoDescription = state.currentTempoDescription
        lastSoundIdentifier = state.lastSoundIdentifier
        lastEventDescription = state.lastEventDescription
        learnedKeysDescription = state.learnedKeysDescription
        adaptiveMappingDescription = state.adaptiveMappingDescription
        performanceDescription = state.performanceDescription
        topKeyStats = state.topKeyStats
        vibeStatusDescription = state.vibeStatusDescription
    }
}

struct NoisyKeysUserPreferences {
    static let standard = NoisyKeysUserPreferences(defaults: .standard)

    private enum Keys {
        static let isNoiseEnabled = "noisyKeys.isNoiseEnabled.v1"
        static let selectedSoundMode = "noisyKeys.selectedSoundMode.v1"
        static let customPianoPitch = "noisyKeys.customPiano.pitch.v1"
        static let customPianoTone = "noisyKeys.customPiano.tone.v1"
        static let customPianoVibe = "noisyKeys.customPiano.vibe.v1"
        static let vibeDetectionEnabled = "noisyKeys.vibeDetection.enabled.v1"
        static let vibeAnalysisMode = "noisyKeys.vibeDetection.analysisMode.v1"
        static let vibeResponseIntensity = "noisyKeys.vibeDetection.responseIntensity.v1"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var isNoiseEnabled: Bool {
        guard defaults.object(forKey: Keys.isNoiseEnabled) != nil else {
            return true
        }

        return defaults.bool(forKey: Keys.isNoiseEnabled)
    }

    var selectedSoundMode: KeyboardSoundMode {
        guard let rawValue = defaults.string(forKey: Keys.selectedSoundMode),
              let mode = KeyboardSoundMode(rawValue: rawValue) else {
            return KeyboardSoundMode.defaultCuratedMode
        }

        return mode
    }

    var customPianoSettings: CustomPianoSettings {
        CustomPianoSettings(
            pitch: customPianoPitch,
            tone: customPianoTone,
            vibe: customPianoVibe
        )
    }

    var typingVibeConfiguration: TypingVibeConfiguration {
        TypingVibeConfiguration(
            isEnabled: isVibeDetectionEnabled,
            mode: vibeAnalysisMode,
            responseIntensity: vibeResponseIntensity
        )
    }

    func setNoiseEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Keys.isNoiseEnabled)
    }

    func setSoundMode(_ mode: KeyboardSoundMode) {
        defaults.set(mode.rawValue, forKey: Keys.selectedSoundMode)
    }

    func setCustomPianoSettings(_ settings: CustomPianoSettings) {
        defaults.set(settings.pitch.rawValue, forKey: Keys.customPianoPitch)
        defaults.set(settings.tone.rawValue, forKey: Keys.customPianoTone)
        defaults.set(settings.vibe.rawValue, forKey: Keys.customPianoVibe)
    }

    func setTypingVibeConfiguration(_ configuration: TypingVibeConfiguration) {
        defaults.set(configuration.isEnabled, forKey: Keys.vibeDetectionEnabled)
        defaults.set(configuration.mode.rawValue, forKey: Keys.vibeAnalysisMode)
        defaults.set(configuration.responseIntensity.rawValue, forKey: Keys.vibeResponseIntensity)
    }

    private var customPianoPitch: CustomPianoPitch {
        guard let rawValue = defaults.string(forKey: Keys.customPianoPitch),
              let pitch = CustomPianoPitch(rawValue: rawValue) else {
            return CustomPianoSettings.default.pitch
        }

        return pitch
    }

    private var customPianoTone: CustomPianoTone {
        guard let rawValue = defaults.string(forKey: Keys.customPianoTone),
              let tone = CustomPianoTone(rawValue: rawValue) else {
            return CustomPianoSettings.default.tone
        }

        return tone
    }

    private var customPianoVibe: CustomPianoVibe {
        guard let rawValue = defaults.string(forKey: Keys.customPianoVibe),
              let vibe = CustomPianoVibe(rawValue: rawValue) else {
            return CustomPianoSettings.default.vibe
        }

        return vibe
    }

    private var isVibeDetectionEnabled: Bool {
        guard defaults.object(forKey: Keys.vibeDetectionEnabled) != nil else {
            return TypingVibeConfiguration.defaultValue.isEnabled
        }

        return defaults.bool(forKey: Keys.vibeDetectionEnabled)
    }

    private var vibeAnalysisMode: VibeAnalysisMode {
        guard let rawValue = defaults.string(forKey: Keys.vibeAnalysisMode),
              let mode = VibeAnalysisMode(rawValue: rawValue) else {
            return TypingVibeConfiguration.defaultValue.mode
        }

        return mode
    }

    private var vibeResponseIntensity: TypingVibeResponseIntensity {
        guard let rawValue = defaults.string(forKey: Keys.vibeResponseIntensity),
              let intensity = TypingVibeResponseIntensity(rawValue: rawValue) else {
            return TypingVibeConfiguration.defaultValue.responseIntensity
        }

        return intensity
    }
}

private struct ControllerSelectionState {
    let soundMode: KeyboardSoundMode
    let profileDisplayName: String
    let profileSummary: String
    let learnedKeysDescription: String
    let adaptiveMappingDescription: String
    let performanceDescription: String
    let topKeyStats: [AdaptiveKeyStat]
    let customPianoSettings: CustomPianoSettings
}

private struct ControllerDisplayState {
    let totalKeyPresses: Int
    let currentTempoDescription: String
    let lastSoundIdentifier: String
    let lastEventDescription: String
    let learnedKeysDescription: String
    let adaptiveMappingDescription: String
    let performanceDescription: String
    let topKeyStats: [AdaptiveKeyStat]
    let vibeStatusDescription: String
}

enum KeyboardEventFilter {
    static func shouldPlay(for event: NSEvent) -> Bool {
        shouldPlay(for: event.type, isARepeat: event.isARepeat)
    }

    static func shouldPlay(for type: NSEvent.EventType, isARepeat: Bool) -> Bool {
        switch type {
        case .keyDown:
            return !isARepeat
        case .flagsChanged:
            return true
        default:
            return false
        }
    }

    static func shouldPlay(for type: CGEventType, isAutoRepeat: Bool) -> Bool {
        switch type {
        case .keyDown:
            return !isAutoRepeat
        case .flagsChanged:
            return true
        default:
            return false
        }
    }

    static func describe(_ event: NSEvent, source: String) -> String {
        switch event.type {
        case .keyDown:
            let keyLabel = keyLabel(for: event)
            return "\(keyLabel) from \(source)"
        case .flagsChanged:
            return "\(modifierLabel(for: event.keyCode)) from \(source)"
        default:
            return "Keyboard event from \(source)"
        }
    }

    static func describe(type: CGEventType, keyCode: UInt16, source: String) -> String {
        switch type {
        case .keyDown:
            return "Key code \(keyCode) from \(source)"
        case .flagsChanged:
            return "\(modifierLabel(for: keyCode)) from \(source)"
        default:
            return "Keyboard event from \(source)"
        }
    }

    private static func keyLabel(for event: NSEvent) -> String {
        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
            return "Key code \(event.keyCode)"
        }

        return switch characters {
        case " ":
            "Space"
        case "\r":
            "Return"
        case "\t":
            "Tab"
        default:
            characters.uppercased()
        }
    }

    private static func modifierLabel(for keyCode: UInt16) -> String {
        switch keyCode {
        case 54, 55:
            "Command"
        case 56, 60:
            "Shift"
        case 57:
            "Caps Lock"
        case 58, 61:
            "Option"
        case 59, 62:
            "Control"
        case 63:
            "Function"
        default:
            "Modifier key \(keyCode)"
        }
    }
}

enum NoisyKeysInstallLocation {
    static func isTemporaryDistributionPath(_ path: String) -> Bool {
        path.hasPrefix("/Volumes/") || path.contains("/AppTranslocation/")
    }

    static func needsApplicationsCopyHint(_ path: String) -> Bool {
        !isApplicationsPath(path) && !isDevelopmentPath(path) && !isTemporaryDistributionPath(path)
    }

    private static func isApplicationsPath(_ path: String) -> Bool {
        path.hasPrefix("/Applications/") || path.hasPrefix("/System/Applications/")
    }

    private static func isDevelopmentPath(_ path: String) -> Bool {
        path.contains("/Library/Developer/Xcode/DerivedData/") ||
            path.contains("/Development/NoisyKeys/") ||
            path.contains("/build/")
    }
}
