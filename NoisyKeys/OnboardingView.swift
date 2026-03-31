//
//  OnboardingView.swift
//  NoisyKeys
//

import SwiftUI

struct OnboardingView: View {
    let controller: KeyboardNoiseController
    @Binding var hasCompletedOnboarding: Bool

    @State private var step: OnboardingStep = .welcome

    private var presetModes: [KeyboardSoundMode] {
        controller.availableSoundModes.filter { $0 != .customMix }
    }

    private var stepIndex: Int {
        OnboardingStep.allCases.firstIndex(of: step) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("First launch")
                            .font(.caption.weight(.bold))
                            .kerning(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.inkPrimary.opacity(0.54))

                        Text("Set up Noisy Keys")
                            .font(.noisyDisplay(size: 42))
                            .foregroundStyle(Color.inkPrimary)

                        Text("A quick setup for access, sound, and menu bar controls.")
                            .font(.title3)
                            .foregroundStyle(Color.inkPrimary.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 20)

                    Button("Skip") {
                        finishOnboarding()
                    }
                    .buttonStyle(NoisyArcadeButtonStyle(fill: .softOutline))
                    .frame(width: 112)
                }

                OnboardingProgressRow(step: step)

                currentStepCard

                HStack(spacing: 12) {
                    if step != .welcome {
                        Button("Back") {
                            moveBack()
                        }
                        .buttonStyle(NoisyArcadeButtonStyle(fill: .softOutline))
                        .frame(width: 120)
                    }

                    Spacer()

                    Button(primaryButtonTitle) {
                        moveForward()
                    }
                    .buttonStyle(NoisyArcadeButtonStyle(fill: step.accentColor))
                    .frame(width: 208)
                }
            }
            .padding(28)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private var currentStepCard: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeCard(controller: controller)
        case .access:
            OnboardingAccessCard(controller: controller)
        case .mood:
            OnboardingMoodCard(
                controller: controller,
                presetModes: presetModes
            )
        case .ready:
            OnboardingReadyCard(controller: controller)
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .welcome:
            "Get Started"
        case .access:
            controller.hasGlobalAccess ? "Choose a Sound" : "Continue"
        case .mood:
            "Continue"
        case .ready:
            "Open Noisy Keys"
        }
    }

    private func moveBack() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.snappy(duration: 0.26)) {
            step = previous
        }
    }

    private func moveForward() {
        if step == .ready {
            finishOnboarding()
            return
        }

        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.snappy(duration: 0.26)) {
            step = next
        }
    }

    private func finishOnboarding() {
        withAnimation(.snappy(duration: 0.26)) {
            hasCompletedOnboarding = true
        }
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case access
    case mood
    case ready

    var title: String {
        switch self {
        case .welcome:
            "Welcome"
        case .access:
            "Access"
        case .mood:
            "Mood"
        case .ready:
            "Ready"
        }
    }

    var accentColor: Color {
        switch self {
        case .welcome:
            .poolAccent
        case .access:
            .butterAccent
        case .mood:
            .tomatoAccent
        case .ready:
            .mintAccent
        }
    }
}

private struct OnboardingProgressRow: View {
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

private struct OnboardingWelcomeCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            VStack(alignment: .leading, spacing: 16) {
                onboardingHeader(
                    eyebrow: "Welcome",
                    title: "Thank you for supporting Noisy Keys",
                    detail: "Noisy Keys is a one-time purchase, and your support helps keep it simple, polished, and independent."
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

private struct OnboardingAccessCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingHeader(
                eyebrow: "Access",
                title: "Enable keyboard access",
                detail: "Input Monitoring lets Noisy Keys respond anywhere on your Mac."
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
                        Text(controller.accessMessage)
                            .font(.callout)
                            .foregroundStyle(Color.inkPrimary.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 12) {
                        Button(controller.isNoiseEnabled ? "Test Sound" : "Turn Sound On") {
                            if controller.isNoiseEnabled {
                                controller.playTestNoise()
                            } else {
                                controller.setNoiseEnabled(true, promptIfNeeded: false)
                            }
                        }
                        .buttonStyle(NoisyArcadeButtonStyle(fill: .tomatoAccent))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: controller.hasGlobalAccess ? "checkmark.seal.fill" : "hand.raised.fill")
                            .foregroundStyle(controller.hasGlobalAccess ? Color.mintAccent : Color.butterAccent)
                        Text(controller.hasGlobalAccess ? "Access is ready." : "Follow the steps above, then click Check Again.")
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

private struct OnboardingMoodCard: View {
    let controller: KeyboardNoiseController
    let presetModes: [KeyboardSoundMode]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingHeader(
                eyebrow: "Mood",
                title: "Choose your starting sound",
                detail: "You can change it any time."
            )

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(presetModes) { mode in
                    Button {
                        controller.setSoundMode(mode)
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
                }
            }

            Text("Selected: \(controller.selectedSoundMode.displayName)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.inkPrimary.opacity(0.76))
        }
        .noisyCard(tint: controller.selectedSoundMode.accentColor)
    }
}

private struct OnboardingReadyCard: View {
    let controller: KeyboardNoiseController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingHeader(
                eyebrow: "Ready",
                title: "You’re ready",
                detail: "Noisy Keys is set up and ready to use."
            )

            HStack(alignment: .top, spacing: 18) {
                OnboardingFactCard(
                    title: "Starting mood",
                    value: controller.selectedSoundMode.displayName,
                    detail: controller.selectedSoundMode.summary,
                    tint: controller.selectedSoundMode.accentColor
                )

                OnboardingFactCard(
                    title: "Menu bar",
                    value: "Piano icon",
                    detail: "Use the piano icon for quick controls.",
                    tint: .poolAccent
                )

                OnboardingFactCard(
                    title: "Access",
                    value: controller.hasGlobalAccess ? "Ready" : "Not yet",
                    detail: controller.hasGlobalAccess
                        ? "Noisy Keys should work anywhere on your Mac."
                        : "You can still finish now and enable Input Monitoring later.",
                    tint: .mintAccent
                )
            }

            HStack(spacing: 12) {
                Button("Test Sound") {
                    controller.playTestNoise()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .tomatoAccent))
                .frame(width: 160)

                HStack(spacing: 8) {
                    NoisyMenuBarGlyph(isEnabled: controller.isNoiseEnabled)
                        .frame(width: 28, height: 20)

                    Text("The menu bar icon is always available for quick controls.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.inkPrimary.opacity(0.78))
                }
            }
        }
        .noisyCard(tint: .mintAccent)
    }
}

private struct OnboardingChecklistItem: View {
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

private struct OnboardingFactCard: View {
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

private func onboardingHeader(eyebrow: String, title: String, detail: String) -> some View {
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

#Preview {
    OnboardingView(
        controller: KeyboardNoiseController(),
        hasCompletedOnboarding: .constant(false)
    )
}
