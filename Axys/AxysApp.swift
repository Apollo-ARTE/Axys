//
//  AxysApp.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI

@main
struct AxysApp: App {
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
		WindowGroup("Axys", id: "home") {
			HomeView()
				.environment(rhinoConnectionManager)
				.environment(appModel)
				.environment(imageTrackingManager)
				.environment(calibrationManager)
		}
		.windowResizability(.contentSize)

		WindowGroup("Toolbar", id: "toolbar") {
			ToolbarView()
				.environment(appModel)
				.environment(rhinoConnectionManager)
		}
		.windowResizability(.contentSize)
		.defaultWindowPlacement { _, _ in
			.init(.utilityPanel)
		}

		WindowGroup(id: "inspector", for: String.self) { entityID in
			InspectorView(entityID: entityID)
				.environment(appModel)
				.environment(rhinoConnectionManager)
				.environment(calibrationManager)
				.frame(width: 300)
		}
		.windowResizability(.contentSize)
		.defaultWindowPlacement { _, _ in
			.init(.utilityPanel)
		}

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
