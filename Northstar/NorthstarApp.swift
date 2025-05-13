//
//  NorthstarApp.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI

@main
struct NorthstarApp: App {
	@State private var appModel: AppModel
	@State private var imageTrackingManager: ImageTrackingManager
	@State private var rhinoConnectionManager: RhinoConnectionManager
	@State private var calibrationManager: CalibrationManager

	init() {
		self.appModel = .shared

		let calibrationManager: CalibrationManager = .shared
		self.calibrationManager = calibrationManager

		self.rhinoConnectionManager = .init(calibrationManager: calibrationManager)
		self.imageTrackingManager = .init(calibrationManager: calibrationManager)
	}

	var body: some Scene {
		WindowGroup("Northstar", id: "home") {
			HomeView()
				.environment(rhinoConnectionManager)
		}
		.windowResizability(.contentSize)

		WindowGroup("Toolbar", id: "toolbar") {
			ToolbarView()
				.environment(appModel)
				.environment(rhinoConnectionManager)
		}
		.windowStyle(.plain)
		.windowResizability(.contentSize)
		.defaultWindowPlacement { _, _ in
			.init(.utilityPanel)
		}

		WindowGroup("Calibration", id: "calibration") {
			CalibrationProcessView()
				.environment(appModel)
				.environment(imageTrackingManager)
				.environment(calibrationManager)
				.frame(width: 320)
		}
		.windowStyle(.plain)

		WindowGroup("Inspector", id: "inspector") {
			InspectorView()
				.environment(appModel)
				.environment(rhinoConnectionManager)
				.environment(calibrationManager)
				.frame(width: 280, height: 320)
		}
		.windowResizability(.contentSize)

		ImmersiveSpace(id: appModel.immersiveSpaceID) {
			ImmersiveView()
				.environment(appModel)
				.environment(imageTrackingManager)
				.environment(rhinoConnectionManager)
				.environment(calibrationManager)
				.onAppear {
					appModel.immersiveSpaceState = .open
				}
				.onDisappear {
					appModel.immersiveSpaceState = .closed
				}
		}
		.immersionStyle(selection: .constant(.mixed), in: .mixed)
	}
}
