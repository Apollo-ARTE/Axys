//
//  ToolbarView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 19/03/25.
//

import SwiftUI

struct ToolbarView: View {
	@Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
	@Environment(\.openImmersiveSpace) private var openImmersiveSpace
	@Environment(\.openWindow) private var openWindow
	@Environment(\.dismissWindow) private var dismissWindow
	
	@Environment(AppModel.self) private var appModel
	@Environment(RhinoConnectionManager.self) private var rhinoConnectionManager
	
	@State private var showInfoPopover = false

    var body: some View {
		@Bindable var appModel = appModel

		HStack {
			Button("Export", systemImage: "square.and.arrow.up.on.square") {
				rhinoConnectionManager.sendExportCommand()
			}
			
			Toggle("Model", systemImage: "cube.fill", isOn: $appModel.showModels)
			Toggle("Robot's Reach", systemImage: "skew", isOn: $appModel.showRobotReach)

			Divider()
				.frame(height: 40)

			Toggle("Calibrate", systemImage: "perspective", isOn: $appModel.showCalibrationWindow)
				.onChange(of: appModel.showCalibrationWindow) {
					if appModel.showCalibrationWindow {
						openCalibrationWindow()
					} else {
						dismissCalibrationWindow()
					}
					Task {
						await toggleImmersiveSpace()
					}
				}
				.disabled(appModel.immersiveSpaceState == .inTransition)

			Toggle("Info", systemImage: "info", isOn: $showInfoPopover)
				.labelStyle(.iconOnly)
				.popover(isPresented: $showInfoPopover, arrowEdge: .bottom) {
					InfoView()
				}

		}
		.toggleStyle(.button)
		.padding()
		.glassBackgroundEffect()
    }

	private func openCalibrationWindow() {
		openWindow(id: "calibration")
	}

	private func dismissCalibrationWindow() {
		dismissWindow(id: "calibration")
	}

	private func toggleCalibration() async {
		await toggleImmersiveSpace()
		if appModel.showCalibrationWindow {
			openCalibrationWindow()
		} else {
			dismissCalibrationWindow()
		}
	}

	@MainActor
	private func toggleImmersiveSpace() async {
			switch appModel.immersiveSpaceState {
			case .open:
				appModel.immersiveSpaceState = .inTransition
				await dismissImmersiveSpace()
			case .closed:
				appModel.immersiveSpaceState = .inTransition
				switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
				case .opened:
					break
				case .userCancelled, .error:
					fallthrough
				@unknown default:
					appModel.immersiveSpaceState = .closed
				}
			case .inTransition:
				break
			}
	}
}

#Preview {
    ToolbarView()
		.environment(AppModel())
		.environment(RhinoConnectionManager())
}
