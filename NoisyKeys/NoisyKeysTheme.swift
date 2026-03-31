//
//  NoisyKeysTheme.swift
//  NoisyKeys
//

import AppKit
import SwiftUI

enum NoisyKeysTheme {
    static let cornerRadius: CGFloat = 28
    static let pressedOffset: CGFloat = 2
}

enum NoisyKeysBuildOptions {
    static var showsDebugReadouts: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}

extension Font {
    static func noisyDisplay(size: CGFloat) -> Font {
        .custom("Avenir Next Rounded", size: size)
    }
}

extension KeyboardSoundMode {
    var symbolName: String {
        switch self {
        case .grandRoom:
            "sparkles.rectangle.stack.fill"
        case .feltBloom:
            "cloud.sun.fill"
        case .jazzClub:
            "music.mic.circle.fill"
        case .midnightBlue:
            "moon.stars.fill"
        case .customMix:
            "slider.horizontal.3"
        }
    }

    var accentColor: Color {
        switch self {
        case .grandRoom:
            .poolAccent
        case .feltBloom:
            .butterAccent
        case .jazzClub:
            .tomatoAccent
        case .midnightBlue:
            .midnightAccent
        case .customMix:
            .mintAccent
        }
    }

    var stickerCopy: String {
        switch self {
        case .grandRoom:
            "Open and bright"
        case .feltBloom:
            "Warm and soft"
        case .jazzClub:
            "Dry and woody"
        case .midnightBlue:
            "Dark and calm"
        case .customMix:
            "Build your sound"
        }
    }
}

struct NoisyCardModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .padding(22)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: NoisyKeysTheme.cornerRadius, style: .continuous)
                        .fill(Color.panelBackground)

                    RoundedRectangle(cornerRadius: NoisyKeysTheme.cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.10))
                }
            }
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: NoisyKeysTheme.cornerRadius, style: .continuous)
                        .stroke(Color.softOutline.opacity(0.68), lineWidth: 1.2)

                    RoundedRectangle(cornerRadius: NoisyKeysTheme.cornerRadius, style: .continuous)
                        .stroke(tint.opacity(0.12), lineWidth: 1.2)
                }
            }
    }
}

extension View {
    func noisyCard(tint: Color = .clear) -> some View {
        modifier(NoisyCardModifier(tint: tint))
    }
}

struct NoisyArcadeButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.inkPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.inkPrimary.opacity(0.12), lineWidth: 1.2)
            )
            .offset(y: configuration.isPressed ? NoisyKeysTheme.pressedOffset : 0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct NoisyModeTileStyle: ButtonStyle {
    let tint: Color
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.inkPrimary)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? tint.opacity(configuration.isPressed ? 0.26 : 0.22) : Color.panelBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected ? tint : Color.softOutline.opacity(0.85),
                        lineWidth: isSelected ? 2.2 : 1.2
                    )
            )
            .offset(y: configuration.isPressed ? 2 : 0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct NoisyMenuBarGlyph: View {
    let isEnabled: Bool

    var body: some View {
        Canvas { context, size in
            let tint = Color.primary.opacity(isEnabled ? 0.96 : 0.52)
            let bedRect = CGRect(
                x: 1,
                y: size.height * 0.42,
                width: size.width * 0.76,
                height: size.height * 0.48
            )

            let bedPath = Path(
                roundedRect: bedRect,
                cornerSize: CGSize(width: 2.4, height: 2.4)
            )
            context.fill(bedPath, with: .color(tint.opacity(0.10)))
            context.stroke(bedPath, with: .color(tint), lineWidth: 1.15)

            let whiteKeyWidth = bedRect.width / 4.0
            for index in 1..<4 {
                let x = bedRect.minX + CGFloat(index) * whiteKeyWidth
                var divider = Path()
                divider.move(to: CGPoint(x: x, y: bedRect.minY + 0.8))
                divider.addLine(to: CGPoint(x: x, y: bedRect.maxY - 0.8))
                context.stroke(divider, with: .color(tint.opacity(0.82)), lineWidth: 1)
            }

            let blackKeyWidth = whiteKeyWidth * 0.42
            let blackKeyHeight = bedRect.height * 0.44
            for position in [0.72, 1.8, 2.88] {
                let rect = CGRect(
                    x: bedRect.minX + whiteKeyWidth * CGFloat(position),
                    y: bedRect.minY,
                    width: blackKeyWidth,
                    height: blackKeyHeight
                )
                let path = Path(
                    roundedRect: rect,
                    cornerSize: CGSize(width: 1.2, height: 1.2)
                )
                context.fill(path, with: .color(tint))
            }

            var stem = Path()
            stem.move(to: CGPoint(x: size.width * 0.80, y: size.height * 0.12))
            stem.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.53))
            stem.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.46))
            context.stroke(stem, with: .color(tint), lineWidth: 1.45)

            let noteHeadRect = CGRect(
                x: size.width * 0.66,
                y: size.height * 0.46,
                width: size.width * 0.24,
                height: size.height * 0.22
            )
            let noteHead = Path(ellipseIn: noteHeadRect)
            context.fill(noteHead, with: .color(tint))

            if !isEnabled {
                var slash = Path()
                slash.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.14))
                slash.addLine(to: CGPoint(x: size.width * 0.94, y: size.height * 0.90))
                context.stroke(slash, with: .color(.primary.opacity(0.48)), lineWidth: 1.35)
            }
        }
        .accessibilityLabel("Noisy Keys")
    }
}

enum NoisyMenuBarStatusImage {
    static func make(isEnabled: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 14)

        let image = NSImage(size: size, flipped: false) { _ in
            let tint = NSColor.black.withAlphaComponent(isEnabled ? 1 : 0.55)
            let fill = NSColor.black.withAlphaComponent(isEnabled ? 0.18 : 0.10)

            let bedRect = NSRect(x: 1.0, y: 1.2, width: 10.8, height: 6.6)
            let bedPath = NSBezierPath(roundedRect: bedRect, xRadius: 2.0, yRadius: 2.0)
            fill.setFill()
            bedPath.fill()
            tint.setStroke()
            bedPath.lineWidth = 1.35
            bedPath.stroke()

            let whiteKeyWidth = bedRect.width / 4.0
            for index in 1..<4 {
                let x = bedRect.minX + CGFloat(index) * whiteKeyWidth
                let divider = NSBezierPath()
                divider.move(to: CGPoint(x: x, y: bedRect.minY + 0.6))
                divider.line(to: CGPoint(x: x, y: bedRect.maxY - 0.6))
                divider.lineWidth = 1.0
                divider.stroke()
            }

            let blackKeyWidth = whiteKeyWidth * 0.48
            let blackKeyHeight = bedRect.height * 0.42
            for position in [0.76, 1.84, 2.92] {
                let rect = NSRect(
                    x: bedRect.minX + CGFloat(position) * whiteKeyWidth,
                    y: bedRect.minY + 0.1,
                    width: blackKeyWidth,
                    height: blackKeyHeight
                )
                let path = NSBezierPath(roundedRect: rect, xRadius: 0.9, yRadius: 0.9)
                tint.setFill()
                path.fill()
            }

            let noteHeadRect = NSRect(x: 11.8, y: 4.0, width: 4.0, height: 3.3)
            let noteHead = NSBezierPath(ovalIn: noteHeadRect)
            tint.setFill()
            noteHead.fill()

            let stem = NSBezierPath()
            stem.move(to: CGPoint(x: 14.6, y: 6.1))
            stem.line(to: CGPoint(x: 14.6, y: 12.0))
            stem.line(to: CGPoint(x: 17.0, y: 10.6))
            stem.lineWidth = 1.6
            stem.lineJoinStyle = .round
            stem.lineCapStyle = .round
            tint.setStroke()
            stem.stroke()

            if !isEnabled {
                let slash = NSBezierPath()
                slash.move(to: CGPoint(x: 1.5, y: 12.2))
                slash.line(to: CGPoint(x: 16.8, y: 1.0))
                slash.lineWidth = 1.5
                slash.lineCapStyle = .round
                tint.setStroke()
                slash.stroke()
            }

            return true
        }

        image.isTemplate = true
        return image
    }
}
