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

	@State private var opacity: Double = 0

	var body: some View {
		@Bindable var appModel = appModel

		VStack(spacing: 32) {
			Text("Visualize")
				.font(.headline)
			HStack(spacing: 32) {
				Toggle("Model", systemImage: "cube.fill", isOn: $appModel.showModels)
				Toggle("Robot's Reach", systemImage: "skew", isOn: $appModel.showRobotReach)
				Toggle("Virtual Lab", systemImage: "baseball.diamond.bases", isOn: $appModel.showVirtualLab)
			}
			Slider(value: $opacity) {
				Label("Opacity", systemImage: "lightspectrum.horizontal")
			}
			.frame(width: 350)
		}
		.toggleStyle(.circluar)
		.padding(32)
		.task {
			await toggleImmersiveSpace()
		}
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

#Preview(windowStyle: .automatic) {
	ToolbarView()
		.environment(AppModel.shared)
        .environment(RhinoConnectionManager.init(calibrationManager: .shared))
}


//			Button("Export", systemImage: "square.and.arrow.up.on.square") {
//				let rn = rhinoConnectionManager
//				rn.sendExportCommand()
//				//				Task {
//				//					await rn.getFilePathForRhinoObjects()
//				//				}
//			}

//			Toggle("Calibrate", systemImage: "perspective", isOn: $appModel.showCalibrationWindow)
//				.onChange(of: appModel.showCalibrationWindow) {
//					if appModel.showCalibrationWindow {
//						openCalibrationWindow()
//					} else {
//						dismissCalibrationWindow()
//					}
//				}
//				.disabled(appModel.immersiveSpaceState == .inTransition)
