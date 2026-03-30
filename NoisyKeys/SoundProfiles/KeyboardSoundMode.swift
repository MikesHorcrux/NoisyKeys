//
//  KeyboardSoundMode.swift
//  NoisyKeys
//

import Foundation

enum KeyboardSoundMode: String, CaseIterable, Identifiable {
    case classicPiano
    case loFiMellow
    case jazz
    case robot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicPiano:
            "Classic Piano"
        case .loFiMellow:
            "Lo-Fi Mellow"
        case .jazz:
            "Jazz"
        case .robot:
            "Robot"
        }
    }

    var summary: String {
        switch self {
        case .classicPiano:
            "Soft, balanced piano with a clean natural tail."
        case .loFiMellow:
            "Sleepy electric keys with a mellow tape wash."
        case .jazz:
            "Woody upright piano with a little more bite and swing."
        case .robot:
            "Sharper synthy keys with a more mechanical edge."
        }
    }

    var instrument: KeyboardInstrument {
        switch self {
        case .classicPiano, .jazz:
            .piano
        case .loFiMellow, .robot:
            .loFiKeys
        }
    }

    var profileID: String {
        switch self {
        case .classicPiano:
            WarmFeltPianoProfile.profile.id
        case .loFiMellow:
            RainWindowLoFiProfile.profile.id
        case .jazz:
            AmberUprightPianoProfile.profile.id
        case .robot:
            SidewalkNeonLoFiProfile.profile.id
        }
    }

    static func preferredMode(for instrument: KeyboardInstrument, profileID: String) -> KeyboardSoundMode {
        if let exactMatch = allCases.first(where: { $0.instrument == instrument && $0.profileID == profileID }) {
            return exactMatch
        }

        switch instrument {
        case .piano:
            return .classicPiano
        case .loFiKeys:
            return .loFiMellow
        }
    }
}
