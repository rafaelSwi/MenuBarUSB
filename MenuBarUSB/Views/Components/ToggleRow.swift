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
    var willRestart: Bool = false
    var onToggle: (Bool) -> Void

    @State private var showIncompatibilityMessage = false
    @State private var showDescription = false
    
    @State private var showRestartMessage = false
    @State private var restartHoverProgress: Double = 0
    @State private var restartTimer: Timer?
    @State private var infoHoverProgress: Double = 0
    @State private var warningHoverProgress: Double = 0
    @State private var infoTimer: Timer?
    @State private var warningTimer: Timer?

    func hasIncompatibility() -> Bool {
        return incompatibilities?.contains(true) ?? false
    }

    private func startHoverProgress(_ interaction: Interaction) {
        let duration: TimeInterval = 1.5
        let step: TimeInterval = 0.05
        var elapsed: TimeInterval = 0
        
        switch (interaction) {
        case .info:
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
                        showRestartMessage = false
                        Utils.System.hapticFeedback()
                    }
                    t.invalidate()
                }
            }
        case .warning:
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
                        showRestartMessage = false
                        Utils.System.hapticFeedback()
                    }
                    t.invalidate()
                }
            }
        case .restart:
            restartHoverProgress = 0
            restartTimer?.invalidate()
            restartTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { t in
                elapsed += step
                let percent = min(elapsed / duration, 1.0)
                restartHoverProgress = percent
                if percent >= 1 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeRowID = id
                        showRestartMessage = true
                        showDescription = false
                        showIncompatibilityMessage = false
                        Utils.System.hapticFeedback()
                    }
                    t.invalidate()
                }
            }
        }
    }
    
    private enum Interaction {
        case info
        case warning
        case restart
    }

    private func cancelHover(_ interaction: Interaction) {
        switch (interaction) {
        case .info:
            infoTimer?.invalidate()
            infoHoverProgress = 0
        case .warning:
            warningTimer?.invalidate()
            warningHoverProgress = 0
        case .restart:
            restartTimer?.invalidate()
            restartHoverProgress = 0
        }
    }

    private func immediateToggle(_ interaction: Interaction) {
        
        switch (interaction) {
        case .info:
            infoTimer?.invalidate()
            infoHoverProgress = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                let newState = !(activeRowID == id && showDescription)
                activeRowID = newState ? id : nil
                showDescription = newState
                showIncompatibilityMessage = false
                showRestartMessage = false
            }
        case .warning:
            warningTimer?.invalidate()
            warningHoverProgress = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                let newState = !(activeRowID == id && showIncompatibilityMessage)
                activeRowID = newState ? id : nil
                showIncompatibilityMessage = newState
                showDescription = false
                showRestartMessage = false
            }
        case .restart:
            restartTimer?.invalidate()
            restartHoverProgress = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                let newState = !(activeRowID == id && showRestartMessage)
                activeRowID = newState ? id : nil
                showRestartMessage = newState
                showDescription = false
                showIncompatibilityMessage = false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(label.localized, isOn: $binding)
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
                        .onTapGesture { immediateToggle(.info) }
                        .onHover { inside in
                            if inside && !showDescription { startHoverProgress(.info) }
                            else { cancelHover(.info) }
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
                
                if willRestart {
                    ZStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.orange)
                            .onTapGesture { immediateToggle(.restart) }
                            .onHover { inside in
                                if inside && !showRestartMessage { startHoverProgress(.restart) }
                                else { cancelHover(.restart) }
                            }

                        if restartHoverProgress > 0 && restartHoverProgress < 1 {
                            Circle()
                                .trim(from: 0, to: restartHoverProgress)
                                .stroke(.orange, lineWidth: 2)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: restartHoverProgress)
                        }
                    }
                    .frame(width: 20, height: 20)
                }

                if hasIncompatibility() {
                    ZStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color("Warning"))
                            .onTapGesture { immediateToggle(.warning) }
                            .onHover { inside in
                                if inside && !showIncompatibilityMessage { startHoverProgress(.warning) }
                                else { cancelHover(.warning) }
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
                Text(description.localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Group {
                
                if activeRowID == id && showIncompatibilityMessage {
                    Text("warning_incompatible_options")
                }
                
                if activeRowID == id && showRestartMessage {
                    Text("app_will_quickly_restart")
                }
                
            }
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
        .padding(.vertical, 1)
        .animation(.easeInOut(duration: 0.25), value: showDescription)
        .animation(.easeInOut(duration: 0.25), value: showIncompatibilityMessage)
        .onDisappear {
            infoTimer?.invalidate()
            warningTimer?.invalidate()
        }
    }
}
