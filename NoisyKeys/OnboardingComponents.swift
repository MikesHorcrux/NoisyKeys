//
//  OnboardingComponents.swift
//  NoisyKeys
//

import SwiftUI

struct OnboardingProgressRow: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(OnboardingStep.allCases.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(index <= step.rawValue ? item.accentColor.opacity(0.84) : Color.softOutline.opacity(0.5))
                            .frame(width: 28, height: 28)

                        if index < step.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.inkPrimary)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.inkPrimary)
                        }
                    }

                    Text(item.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.inkPrimary.opacity(index == step.rawValue ? 1 : 0.64))
                }

                if index < OnboardingStep.allCases.count - 1 {
                    Capsule()
                        .fill(index < step.rawValue ? item.accentColor.opacity(0.44) : Color.softOutline.opacity(0.44))
                        .frame(height: 4)
                }
            }
        }
        .padding(18)
        .noisyCard(tint: step.accentColor)
    }
}

struct OnboardingWelcomeCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            VStack(alignment: .leading, spacing: 16) {
                onboardingHeader(
                    eyebrow: "Welcome",
                    title: "Thank you for supporting Noisy Keys",
                    detail: "Your support helps keep Noisy Keys simple, polished, and independent."
                )

                OnboardingChecklistItem(
                    icon: "keyboard",
                    title: "Use it across your Mac",
                    detail: "Grant Input Monitoring to hear Noisy Keys outside the app."
                )

                OnboardingChecklistItem(
                    icon: "music.note.house",
                    title: "Choose a sound",
                    detail: "Start with Grand Room, Felt Bloom, Jazz Club, or Midnight Blue."
                )

                OnboardingChecklistItem(
                    icon: "menubar.rectangle",
                    title: "Control it from the menu bar",
                    detail: "Switch sounds or turn it off at any time."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Preview")
                        .font(.headline)

                    Spacer()

                    Text("LIVE")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.mintAccent.opacity(0.24))
                        )
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.panelBackground.opacity(0.92))

                    VStack(spacing: 18) {
                        NoisyMenuBarGlyph(isEnabled: true)
                            .frame(width: 86, height: 60)

                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill((index.isMultiple(of: 2) ? controller.selectedSoundMode.accentColor : Color.butterAccent).opacity(0.88))
                                    .frame(width: 24, height: [42, 68, 52, 78][index])
                            }
                        }
                    }
                    .padding(18)
                }
                .frame(width: 280, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(controller.selectedSoundMode.accentColor.opacity(0.24), lineWidth: 1.2)
                )

                Text("Thanks again for supporting Noisy Keys. This quick setup gets everything ready.")
                    .font(.callout)
                    .foregroundStyle(Color.inkPrimary.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 300)
        }
        .noisyCard(tint: .poolAccent)
    }
}

struct OnboardingAccessCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingHeader(
                eyebrow: "Access",
                title: "Enable keyboard access",
                detail: "Allow Input Monitoring so Noisy Keys can respond anywhere on your Mac."
            )

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    OnboardingFactCard(
                        title: "Current scope",
                        value: controller.monitoringScope,
                        detail: controller.hasGlobalAccess
                            ? "Noisy Keys can work across your Mac."
                            : "Noisy Keys only works in the app until access is approved.",
                        tint: .poolAccent
                    )

                    OnboardingFactCard(
                        title: "Keyboard sound",
                        value: controller.isNoiseEnabled ? "Enabled" : "Off",
                        detail: controller.isNoiseEnabled
                            ? "Sound is ready."
                            : "Turn sound back on before you finish setup.",
                        tint: .mintAccent
                    )
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Next step")
                        .font(.headline)
                        .foregroundStyle(Color.inkPrimary)

                    if !controller.hasGlobalAccess {
                        PermissionGuidanceView(controller: controller)
                    } else {
                        Text("Access is on. Noisy Keys can respond across your Mac.")
                            .font(.callout)
                            .foregroundStyle(Color.inkPrimary.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(controller.isNoiseEnabled ? "Preview Sound" : "Turn Sound On") {
                        if controller.isNoiseEnabled {
                            controller.previewSelectedSound()
                        } else {
                            controller.setNoiseEnabled(true, promptIfNeeded: false)
                        }
                    }
                    .buttonStyle(NoisyArcadeButtonStyle(fill: .tomatoAccent))

                    HStack(spacing: 8) {
                        Image(systemName: controller.hasGlobalAccess ? "checkmark.seal.fill" : "hand.raised.fill")
                            .foregroundStyle(controller.hasGlobalAccess ? Color.mintAccent : Color.butterAccent)
                        Text(controller.hasGlobalAccess ? "Access is ready." : "Follow the steps above, then choose Check Again.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.inkPrimary.opacity(0.78))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.panelBackground.opacity(0.94))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.butterAccent.opacity(0.26), lineWidth: 1.1)
                )
            }
        }
        .noisyCard(tint: .butterAccent)
    }
}

struct OnboardingMoodCard: View {
    let controller: KeyboardNoiseController
    let presetModes: [KeyboardSoundMode]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingHeader(
                eyebrow: "Sound",
                title: "Choose a starting sound",
                detail: "Pick one now. You can change it later."
            )

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(presetModes) { mode in
                    Button {
                        controller.selectSoundMode(mode)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: mode.symbolName)
                                    .font(.title3.weight(.bold))
                                Spacer()
                                if mode == controller.selectedSoundMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.headline)
                                }
                            }

                            Text(mode.displayName)
                                .font(.headline)

                            Text(mode.summary)
                                .font(.callout)
                                .foregroundStyle(Color.inkPrimary.opacity(0.68))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(NoisyModeTileStyle(tint: mode.accentColor, isSelected: mode == controller.selectedSoundMode))
                    .accessibilityIdentifier("onboarding.sound.\(mode.rawValue)")
                }
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selected sound")
                        .font(.caption.weight(.bold))
                        .kerning(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.inkPrimary.opacity(0.56))

                    Text(controller.selectedSoundMode.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.inkPrimary)
                        .accessibilityIdentifier("onboarding.selectedSound")

                    Text(controller.selectedSoundMode.summary)
                        .font(.callout)
                        .foregroundStyle(Color.inkPrimary.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button("Preview Sound") {
                    controller.previewSelectedSound()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: controller.selectedSoundMode.accentColor))
                .frame(width: 180)
                .accessibilityIdentifier("onboarding.previewSound")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.panelBackground.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(controller.selectedSoundMode.accentColor.opacity(0.28), lineWidth: 1.2)
            )
        }
        .noisyCard(tint: controller.selectedSoundMode.accentColor)
    }
}

struct OnboardingReadyCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingHeader(
                eyebrow: "Ready",
                title: "You’re ready",
                detail: "Noisy Keys is ready when you are."
            )

            HStack(alignment: .top, spacing: 18) {
                OnboardingFactCard(
                    title: "Sound",
                    value: controller.selectedSoundMode.displayName,
                    detail: controller.selectedSoundMode.summary,
                    tint: controller.selectedSoundMode.accentColor
                )

                OnboardingFactCard(
                    title: "Menu bar",
                    value: "Piano icon",
                    detail: "Use it for quick controls any time.",
                    tint: .poolAccent
                )

                OnboardingFactCard(
                    title: "Access",
                    value: controller.hasGlobalAccess ? "Ready" : "Not yet",
                    detail: controller.hasGlobalAccess
                        ? "Noisy Keys can work across your Mac."
                        : "You can finish now and enable Input Monitoring later.",
                    tint: .mintAccent
                )
            }

            HStack(spacing: 12) {
                Button("Preview Sound") {
                    controller.previewSelectedSound()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .tomatoAccent))
                .frame(width: 160)

                HStack(spacing: 8) {
                    NoisyMenuBarGlyph(isEnabled: controller.isNoiseEnabled)
                        .frame(width: 28, height: 20)

                    Text("The menu bar icon is always there for quick controls.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.inkPrimary.opacity(0.78))
                }
            }
        }
        .noisyCard(tint: .mintAccent)
    }
}

struct OnboardingChecklistItem: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.inkPrimary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.poolAccent.opacity(0.18))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.inkPrimary)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.inkPrimary.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct OnboardingFactCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .kerning(1)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkPrimary.opacity(0.58))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.inkPrimary)

            Text(detail)
                .font(.callout)
                .foregroundStyle(Color.inkPrimary.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(tint.opacity(0.24), lineWidth: 1.1)
        )
    }
}

@ViewBuilder
func onboardingHeader(eyebrow: String, title: String, detail: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(eyebrow)
            .font(.caption.weight(.bold))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Color.inkPrimary.opacity(0.54))

        Text(title)
            .font(.noisyDisplay(size: 34))
            .foregroundStyle(Color.inkPrimary)

        Text(detail)
            .font(.callout)
            .foregroundStyle(Color.inkPrimary.opacity(0.70))
            .fixedSize(horizontal: false, vertical: true)
    }
}
