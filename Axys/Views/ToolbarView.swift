//
//  ToolbarView.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 19/03/25.
//

import SwiftUI

struct ToolbarView: View {
	@Environment(\.openWindow) private var openWindow
	@Environment(\.dismissWindow) private var dismissWindow
	@Environment(AppModel.self) private var appModel
	@Environment(RhinoConnectionManager.self) private var rhinoConnectionManager

	var body: some View {
		@Bindable var appModel = appModel

		VStack(spacing: 32) {
			Text("Visualize")
				.font(.headline)
			HStack(spacing: 32) {
				Toggle("Models", systemImage: "cube.fill", isOn: $appModel.showModels)
				Toggle("Reach", systemImage: "skew", isOn: $appModel.showRobotReach)
				Toggle("Virtual Lab", systemImage: "baseball.diamond.bases", isOn: $appModel.showVirtualLab)
			}
		}
		.toggleStyle(.circluar)
		.overlay(alignment: .topLeading) {
			Button("Close", systemImage: "xmark") {
				openWindow(id: "home")
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.circle)
			.labelStyle(.iconOnly)
		}
		.padding(32)
		.task {
			await rhinoConnectionManager.addObjectsToView()
		}
		.onAppear {
			dismissWindow(id: "home")
		}
	}
}

#Preview(windowStyle: .automatic) {
	ToolbarView()
		.environment(AppModel.shared)
        .environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
