//
//  OnboardingView.swift
//  NoisyKeys
//

import SwiftUI

struct OnboardingView: View {
    let controller: KeyboardNoiseController
    @Binding var hasCompletedOnboarding: Bool

    @State private var step: OnboardingStep = .welcome
    @State private var hasPreparedStartingSound = false

    private var presetModes: [KeyboardSoundMode] {
        KeyboardSoundMode.curatedModes
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                onboardingTopBar
                OnboardingProgressRow(step: step)
                currentStepCard
                    .accessibilityIdentifier("onboarding.step.\(step.identifier)")
                onboardingFooter
            }
            .padding(28)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("onboarding.root")
        .onAppear(perform: prepareOnboardingState)
    }

    private var onboardingTopBar: some View {
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

                Text("A quick setup for access, sound, and the menu bar.")
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
            .accessibilityIdentifier("onboarding.skipButton")
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

    private var onboardingFooter: some View {
        HStack(spacing: 12) {
            if step != .welcome {
                Button("Back") {
                    moveBack()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .softOutline))
                .frame(width: 120)
                .accessibilityIdentifier("onboarding.backButton")
            }

            Spacer()

            Button(primaryButtonTitle) {
                moveForward()
            }
            .buttonStyle(NoisyArcadeButtonStyle(fill: step.accentColor))
            .frame(width: 208)
            .accessibilityIdentifier("onboarding.primaryButton")
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .welcome, .access, .mood:
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

    private func prepareOnboardingState() {
        guard !hasPreparedStartingSound else { return }
        hasPreparedStartingSound = true

        guard !presetModes.contains(controller.selectedSoundMode) else { return }
        controller.selectSoundMode(KeyboardSoundMode.defaultCuratedMode)
    }
}

enum OnboardingStep: Int, CaseIterable {
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
            "Sound"
        case .ready:
            "Ready"
        }
    }

    var identifier: String {
        switch self {
        case .welcome:
            "welcome"
        case .access:
            "access"
        case .mood:
            "sound"
        case .ready:
            "ready"
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

#Preview {
    OnboardingView(
        controller: KeyboardNoiseController(),
        hasCompletedOnboarding: .constant(false)
    )
}
