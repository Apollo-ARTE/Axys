//
//  InspectorView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 08/04/25.
//

import SwiftUI

struct InspectorView: View {
	enum Axes {
		case x, y, z
	}

	@Environment(AppModel.self) private var appModel
	@Environment(RhinoConnectionManager.self) private var connectionManager

	var body: some View {
		@Bindable var connectionManager = connectionManager
		VStack {
			Text("Inspector")
			TextField("X", value: objectX(axes: .x), format: .number)
			TextField("Y", value: objectX(axes: .y), format: .number)
			TextField("Z", value: objectX(axes: .z), format: .number)
		}
		.textFieldStyle(.roundedBorder)
		.keyboardType(.numbersAndPunctuation)
		.padding(32)
	}

	private func objectX(axes: Axes) -> Binding<Float> {
		Binding {
			let position = appModel.selectedEntity?.position
			switch axes {
			case .x:
				return position?.x ?? 0
			case .y:
				return position?.y ?? 0
			case .z:
				return position?.z ?? 0
			}
		} set: { value in
			switch axes {
			case .x:
				appModel.selectedEntity?.position.x = value
			case .y:
				appModel.selectedEntity?.position.y = value
			case .z:
				appModel.selectedEntity?.position.z = value
			}

			guard let entity = appModel.selectedEntity else { return }

			let newPosition = CalibrationManager.shared.convertLocalToRobot(local: [
				appModel.selectedEntity?.position.x ?? 0,
				appModel.selectedEntity?.position.y ?? 0,
				appModel.selectedEntity?.position.z ?? 0
			])
			connectionManager.sendPositionUpdate(for: entity, newPosition: newPosition)
		}
	}
}

#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 280, height: 320)) {
	InspectorView()
		.environment(AppModel.shared)
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
