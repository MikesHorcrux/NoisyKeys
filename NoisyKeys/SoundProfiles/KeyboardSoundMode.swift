//
//  KeyboardSoundMode.swift
//  NoisyKeys
//

import Foundation

enum KeyboardSoundMode: String, CaseIterable, Identifiable {
    case grandRoom
    case feltBloom
    case jazzClub
    case midnightBlue
    case customMix

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grandRoom:
            "Grand Room"
        case .feltBloom:
            "Felt Bloom"
        case .jazzClub:
            "Jazz Club"
        case .midnightBlue:
            "Midnight Blue"
        case .customMix:
            "Custom Mix"
        }
    }

    var summary: String {
        switch self {
        case .grandRoom:
            "Open grand piano with a wider room and brighter bloom."
        case .feltBloom:
            "Soft felt piano with warm body and creamy tails."
        case .jazzClub:
            "Woody upright piano with smoky mids and a tighter bounce."
        case .midnightBlue:
            "Dark cinematic piano with cooler air and longer resolve."
        case .customMix:
            "Choose your own pitch, tone, and vibe."
        }
    }

    var instrument: KeyboardInstrument {
        .piano
    }

    var profileID: String {
        switch self {
        case .grandRoom:
            ConcertHallPianoProfile.profile.id
        case .feltBloom:
            WarmFeltPianoProfile.profile.id
        case .jazzClub:
            AmberUprightPianoProfile.profile.id
        case .midnightBlue:
            MoonlightPianoProfile.profile.id
        case .customMix:
            CustomPianoProfileBuilder.profileID
        }
    }

    static func preferredMode(for instrument: KeyboardInstrument, profileID: String) -> KeyboardSoundMode {
        if let exactMatch = allCases.first(where: { $0.instrument == instrument && $0.profileID == profileID }) {
            return exactMatch
        }

        switch instrument {
        case .piano:
            return .feltBloom
        case .loFiKeys:
            return .feltBloom
        }
    }
}
