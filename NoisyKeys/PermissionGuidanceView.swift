//
//  PermissionGuidanceView.swift
//  NoisyKeys
//

import SwiftUI

struct PermissionGuidanceView: View {
    let controller: KeyboardNoiseController
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "hand.raised.fill")
                    .font(.headline)
                    .foregroundStyle(Color.inkPrimary)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.butterAccent.opacity(0.24))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard access")
                        .font(.headline)
                        .foregroundStyle(Color.inkPrimary)

                    Text(controller.inputMonitoringPath)
                        .font(compact ? .caption : .callout)
                        .foregroundStyle(Color.inkPrimary.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if compact {
                Text("Turn on Noisy Keys, then choose Check Again.")
                    .font(.callout)
                    .foregroundStyle(Color.inkPrimary.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(controller.permissionSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.inkPrimary)
                                .frame(width: 18, alignment: .leading)

                            Text(step)
                                .font(.callout)
                                .foregroundStyle(Color.inkPrimary.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Text(controller.accessMessage)
                .font(.caption)
                .foregroundStyle(Color.inkPrimary.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Open System Settings") {
                    controller.openInputMonitoringSettings()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .butterAccent))

                Button("Check Again") {
                    controller.checkAccessAgain()
                }
                .buttonStyle(NoisyArcadeButtonStyle(fill: .softOutline))
            }
        }
        .padding(compact ? 16 : 18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.butterAccent.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.butterAccent.opacity(0.28), lineWidth: 1.1)
        )
    }
}

#Preview {
    PermissionGuidanceView(controller: KeyboardNoiseController())
        .padding()
}
