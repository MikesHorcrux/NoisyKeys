//
//  KeyboardNoiseController.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import AppKit
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

    private let player = KeyboardSynthPlayer()
    private let playbackQueue = DispatchQueue(label: "NoisyKeys.Playback")
    private var musicEngine = KeyboardMusicEngine(persistentLearning: true)
    private var localMonitor: Any?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var isEventTapActive = false
    private var hasStarted = false
    private var processedKeyPresses = 0
    private var pendingDisplayState: ControllerDisplayState?
    private var displayRefreshWorkItem: DispatchWorkItem?
    private let displayRefreshInterval: TimeInterval = 0.08

    init() {
        let selectionState = makeSelectionState()
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
            "Open System Settings.",
            "Open Privacy & Security, then Input Monitoring.",
            "Turn on Noisy Keys.",
            "Return here and click Check Again."
        ]
    }

    func start() {
        guard !hasStarted else { return }

        hasStarted = true
        setNoiseEnabled(true, promptIfNeeded: true)
    }

    func setNoiseEnabled(_ isEnabled: Bool, promptIfNeeded: Bool = false) {
        isNoiseEnabled = isEnabled

        guard hasStarted else { return }

        if isEnabled {
            installLocalMonitorIfNeeded()
            refreshAccessStatus(promptIfNeeded: promptIfNeeded)
        } else {
            removeLocalMonitor()
            disableEventTap()
            resetPlaybackState()
            accessMessage = hasGlobalAccess
                ? "Sound is off. Turn it on when you want to use Noisy Keys."
                : "Sound is off. Allow access later to use Noisy Keys across your Mac."
        }
    }

    func refreshAccessStatus(promptIfNeeded: Bool = false) {
        let hasAccess = promptIfNeeded ? CGRequestListenEventAccess() : CGPreflightListenEventAccess()
        hasGlobalAccess = hasAccess

        if hasAccess {
            accessMessage = isNoiseEnabled
                ? "Keyboard access is on across your Mac."
                : "Access is ready. Sound is off."
            if isNoiseEnabled {
                installEventTapIfNeeded()
            }
        } else {
            disableEventTap()
            accessMessage = isNoiseEnabled
                ? "Allow Noisy Keys in System Settings > Privacy & Security > Input Monitoring."
                : "Sound is off. Allow Input Monitoring later to use Noisy Keys across your Mac."
        }
    }

    func checkAccessAgain() {
        refreshAccessStatus(promptIfNeeded: false)
    }

    func openInputMonitoringSettings() {
        let settingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        _ = NSWorkspace.shared.open(settingsURL)
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

    private func installLocalMonitorIfNeeded() {
        guard localMonitor == nil else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleLocalEvent(event)
            return event
        }
    }

    private func installEventTapIfNeeded() {
        guard CGPreflightListenEventAccess() else { return }

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isEventTapActive = true
            return
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
            accessMessage = "Keyboard access could not start. Allow Input Monitoring and try again."
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        eventTapSource = runLoopSource
        isEventTapActive = true
    }

    private func handleLocalEvent(_ event: NSEvent) {
        guard isNoiseEnabled else { return }
        guard !isEventTapActive else { return }
        guard let input = KeyboardInputTranslator.input(for: event, source: .localApp) else { return }

        enqueueProcessing(input, countAsKeyPress: true)
    }

    private func stop() {
        removeLocalMonitor()
        tearDownEventTap()
    }

    private func handleEventTap(type: CGEventType, keyCode: UInt16, isAutoRepeat: Bool) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if isNoiseEnabled, let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
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
            topKeyStats: musicEngine.topKeyStats
        )
    }

    private func updateCustomPianoSettings(_ settings: CustomPianoSettings) {
        let selectionState = playbackQueue.sync { [self] in
            musicEngine.setCustomPianoSettings(settings)
            return makeSelectionState()
        }
        applySelectionState(selectionState)
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
