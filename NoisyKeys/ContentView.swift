//
//  ContentView.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: KeyboardNoiseController

    @AppStorage("hasCompletedOnboarding_v4") private var hasCompletedOnboarding = false
    @State private var showsDebugReadouts = false
    @State private var hasAppliedLaunchOverrides = false

    private var forcesOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_RESET_ONBOARDING")
    }

    var body: some View {
        ZStack {
            NoisyBackgroundView(mode: controller.selectedSoundMode)

            if hasCompletedOnboarding && !forcesOnboardingForUITests {
                DashboardScreen(
                    controller: controller,
                    showsDebugReadouts: $showsDebugReadouts
                )
                .transition(.opacity)
            } else {
                OnboardingView(
                    controller: controller,
                    hasCompletedOnboarding: $hasCompletedOnboarding
                )
                .transition(.opacity)
            }
        }
        .animation(.snappy(duration: 0.26), value: hasCompletedOnboarding)
        .frame(minWidth: 860, minHeight: 680)
        .onAppear(perform: applyLaunchOverridesIfNeeded)
    }

    private func applyLaunchOverridesIfNeeded() {
        guard !hasAppliedLaunchOverrides else { return }
        hasAppliedLaunchOverrides = true

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("UITEST_RESET_ONBOARDING") {
            hasCompletedOnboarding = false
            controller.selectSoundMode(KeyboardSoundMode.defaultCuratedMode)
        }
    }
}

#Preview {
    ContentView(controller: KeyboardNoiseController())
}
