//
//  ToggleRow.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import Combine
import SwiftUI

struct ToggleRow: View {
    let id: UUID = .init()
    let label: String
    let description: String
    @Binding var binding: Bool
    @Binding var activeRowID: UUID?
    let incompatibilities: [Bool]?
    var disabled: Bool = false
    var onToggle: (Bool) -> Void

    @State private var showIncompatibilityMessage = false
    @State private var showDescription = false

    @State private var infoHoverProgress: Double = 0
    @State private var warningHoverProgress: Double = 0
    @State private var infoTimer: Timer?
    @State private var warningTimer: Timer?

    func hasIncompatibility() -> Bool {
        return incompatibilities?.contains(true) ?? false
    }

    private func startHoverProgress(forInfo: Bool) {
        let duration: TimeInterval = 1.5
        let step: TimeInterval = 0.05
        var elapsed: TimeInterval = 0

        if forInfo {
            infoHoverProgress = 0
            infoTimer?.invalidate()
            infoTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { t in
                elapsed += step
                let percent = min(elapsed / duration, 1.0)
                infoHoverProgress = percent
                if percent >= 1 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeRowID = id
                        showDescription = true
                        showIncompatibilityMessage = false
                        Utils.System.hapticFeedback()
                    }
                    t.invalidate()
                }
            }
        } else {
            warningHoverProgress = 0
            warningTimer?.invalidate()
            warningTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { t in
                elapsed += step
                let percent = min(elapsed / duration, 1.0)
                warningHoverProgress = percent
                if percent >= 1 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeRowID = id
                        showIncompatibilityMessage = true
                        showDescription = false
                        Utils.System.hapticFeedback()
                    }
                    t.invalidate()
                }
            }
        }
    }

    private func cancelHover(forInfo: Bool) {
        if forInfo {
            infoTimer?.invalidate()
            infoHoverProgress = 0
        } else {
            warningTimer?.invalidate()
            warningHoverProgress = 0
        }
    }

    private func immediateToggle(forInfo: Bool) {
        if forInfo {
            infoTimer?.invalidate()
            infoHoverProgress = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                let newState = !(activeRowID == id && showDescription)
                activeRowID = newState ? id : nil
                showDescription = newState
                showIncompatibilityMessage = false
            }
        } else {
            warningTimer?.invalidate()
            warningHoverProgress = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                let newState = !(activeRowID == id && showIncompatibilityMessage)
                activeRowID = newState ? id : nil
                showIncompatibilityMessage = newState
                showDescription = false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(label, isOn: $binding)
                    .onChange(of: binding) { newValue in
                        onToggle(newValue)
                        if !newValue && activeRowID == id {
                            activeRowID = nil
                        }
                    }
                    .toggleStyle(.checkbox)
                    .disabled(disabled)

                ZStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color("Info"))
                        .onTapGesture { immediateToggle(forInfo: true) }
                        .onHover { inside in
                            if inside && !showDescription { startHoverProgress(forInfo: true) }
                            else { cancelHover(forInfo: true) }
                        }

                    if infoHoverProgress > 0 && infoHoverProgress < 1 {
                        Circle()
                            .trim(from: 0, to: infoHoverProgress)
                            .stroke(Color("Info"), lineWidth: 2)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear, value: infoHoverProgress)
                    }
                }
                .frame(width: 20, height: 20)

                if hasIncompatibility() {
                    ZStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color("Warning"))
                            .onTapGesture { immediateToggle(forInfo: false) }
                            .onHover { inside in
                                if inside && !showIncompatibilityMessage { startHoverProgress(forInfo: false) }
                                else { cancelHover(forInfo: false) }
                            }

                        if warningHoverProgress > 0 && warningHoverProgress < 1 {
                            Circle()
                                .trim(from: 0, to: warningHoverProgress)
                                .stroke(Color("Warning"), lineWidth: 2)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: warningHoverProgress)
                        }
                    }
                    .frame(width: 22, height: 22)
                }

                Spacer()
            }

            if activeRowID == id && showDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if activeRowID == id && showIncompatibilityMessage {
                Text("warning_incompatible_options")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(
                        Color("Warning")
                            .opacity(0.4)
                            .cornerRadius(8)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showDescription)
        .animation(.easeInOut(duration: 0.25), value: showIncompatibilityMessage)
        .onDisappear {
            infoTimer?.invalidate()
            warningTimer?.invalidate()
        }
    }
}
