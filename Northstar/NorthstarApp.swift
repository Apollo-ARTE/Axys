//
//  NorthstarApp.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI

@main
struct NorthstarApp: App {

    @State private var appModel = AppModel()
	@State private var imageTracking = ImageTracking()

    var body: some Scene {
		WindowGroup("Northstar", id: "toolbar") {
			ToolbarView()
				.environment(appModel)
				.environment(imageTracking)
        }
		.windowStyle(.plain)
		.windowResizability(.contentSize)
		.defaultWindowPlacement { content, context in
				.init(.utilityPanel)
		}

		WindowGroup("Calibration", id: "calibration") {
			CalibrationProcessView()
				.frame(width: 320)
		}
		.windowResizability(.contentSize)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
				.environment(imageTracking)
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
