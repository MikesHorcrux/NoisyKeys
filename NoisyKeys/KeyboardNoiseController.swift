//
//  KeyboardNoiseController.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import AVFoundation
import AppKit
import CoreGraphics
import Foundation
import Observation

@Observable
final class KeyboardNoiseController {
    var isNoiseEnabled = true
    var hasGlobalAccess = false
    var selectedInstrument: KeyboardInstrument = .piano
    var selectedSoundMode: KeyboardSoundMode = .classicPiano
    var selectedSoundModeSummary = KeyboardSoundMode.classicPiano.summary
    var selectedProfileID = PianoProfileCatalog.defaultProfile.id
    var selectedProfileDisplayName = PianoProfileCatalog.defaultProfile.displayName
    var selectedProfileSummary = PianoProfileCatalog.defaultProfile.summary
    var accessMessage = "Checking keyboard access..."
    var lastEventDescription = "Waiting for the first clack."
    var lastSoundIdentifier = "Waiting for the first mapped sound."
    var currentTempoDescription = TypingTempoSnapshot.idle.summary
    var learnedKeysDescription = "Learning your letter habits."
    var adaptiveMappingDescription = "Frequent letters will settle into the safest note families."
    var performanceDescription = "Warm piano · neutral tone"
    var totalKeyPresses = 0

    private let player = KeyboardSynthPlayer()
    private var musicEngine = KeyboardMusicEngine(persistentLearning: true)
    private var localMonitor: Any?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var hasStarted = false

    init() {
        selectedInstrument = musicEngine.instrument
        selectedSoundMode = musicEngine.currentSoundMode
        selectedSoundModeSummary = musicEngine.currentSoundMode.summary
        selectedProfileID = musicEngine.currentProfileID
        selectedProfileDisplayName = musicEngine.currentProfileDisplayName
        selectedProfileSummary = musicEngine.currentProfileSummary
        learnedKeysDescription = musicEngine.learnedKeysSummary
        adaptiveMappingDescription = musicEngine.adaptiveMappingDescription
        performanceDescription = musicEngine.performanceDescription
    }

    deinit {
        stop()
    }

    var monitoringScope: String {
        if isNoiseEnabled {
            return hasGlobalAccess ? "System-wide" : "Inside NoisyKeys"
        }

        return hasGlobalAccess ? "Off (System-wide ready)" : "Off"
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
            player.resetPerformanceState()
            accessMessage = hasGlobalAccess
                ? "Noise is off. Flip it back on from the menu bar whenever you want more clacks."
                : "Noise is off. Grant Input Monitoring later if you want system-wide key sounds."
        }
    }

    func refreshAccessStatus(promptIfNeeded: Bool = false) {
        let hasAccess = promptIfNeeded ? CGRequestListenEventAccess() : CGPreflightListenEventAccess()
        hasGlobalAccess = hasAccess

        if hasAccess {
            accessMessage = isNoiseEnabled
                ? "Keyboard listening is active across macOS."
                : "System-wide access is ready. Noise is currently off."
            if isNoiseEnabled {
                installEventTapIfNeeded()
            }
        } else {
            disableEventTap()
            accessMessage = isNoiseEnabled
                ? "Allow NoisyKeys in System Settings > Privacy & Security > Input Monitoring for system-wide key sounds."
                : "Noise is off. Allow Input Monitoring later if you want it working across the whole Mac."
        }
    }

    func playTestNoise() {
        let plan = musicEngine.previewPlan(for: .space)
        applyPlan(plan, countAsKeyPress: false)
    }

    var availableSoundModes: [KeyboardSoundMode] {
        musicEngine.availableSoundModes
    }

    var availableProfiles: [ProfileOption] {
        musicEngine.availableProfileOptions
    }

    func setInstrument(_ instrument: KeyboardInstrument) {
        player.resetPerformanceState()
        selectedInstrument = instrument
        musicEngine.setInstrument(instrument)
        syncSelectionState()
        learnedKeysDescription = musicEngine.learnedKeysSummary
        adaptiveMappingDescription = musicEngine.adaptiveMappingDescription
        performanceDescription = musicEngine.performanceDescription
    }

    func setSoundMode(_ mode: KeyboardSoundMode) {
        player.resetPerformanceState()
        musicEngine.setSoundMode(mode)
        syncSelectionState()
        learnedKeysDescription = musicEngine.learnedKeysSummary
        adaptiveMappingDescription = musicEngine.adaptiveMappingDescription
        performanceDescription = musicEngine.performanceDescription
    }

    func setProfile(id: String) {
        player.resetPerformanceState()
        musicEngine.setCurrentProfile(id: id)
        syncSelectionState()
        learnedKeysDescription = musicEngine.learnedKeysSummary
        adaptiveMappingDescription = musicEngine.adaptiveMappingDescription
        performanceDescription = musicEngine.performanceDescription
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
            accessMessage = "macOS did not create the keyboard event tap yet. Grant Input Monitoring and try again."
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        eventTapSource = runLoopSource
    }

    private func handleLocalEvent(_ event: NSEvent) {
        guard isNoiseEnabled else { return }
        guard eventTap == nil else { return }
        guard let input = KeyboardInputTranslator.input(for: event, source: .localApp) else { return }

        applyPlan(musicEngine.plan(for: input), countAsKeyPress: true)
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

        applyPlan(musicEngine.plan(for: input), countAsKeyPress: true)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let controller = Unmanaged<KeyboardNoiseController>.fromOpaque(userInfo).takeUnretainedValue()
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        DispatchQueue.main.async {
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
    }

    private func applyPlan(_ plan: SoundTriggerPlan, countAsKeyPress: Bool) {
        if countAsKeyPress {
            totalKeyPresses += 1
        }

        currentTempoDescription = plan.tempo.summary
        lastSoundIdentifier = plan.soundID
        lastEventDescription = plan.debugSummary
        learnedKeysDescription = musicEngine.learnedKeysSummary
        adaptiveMappingDescription = musicEngine.adaptiveMappingDescription
        performanceDescription = musicEngine.performanceDescription
        player.play(plan)
    }

    private func syncSelectionState() {
        selectedInstrument = musicEngine.instrument
        selectedSoundMode = musicEngine.currentSoundMode
        selectedSoundModeSummary = musicEngine.currentSoundMode.summary
        selectedProfileID = musicEngine.currentProfileID
        selectedProfileDisplayName = musicEngine.currentProfileDisplayName
        selectedProfileSummary = musicEngine.currentProfileSummary
    }
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
