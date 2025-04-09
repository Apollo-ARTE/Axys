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
	@Environment(CalibrationManager.self) private var calibrationManager

	var body: some View {
		@Bindable var connectionManager = connectionManager
		VStack {
			Text("Inspector")
			TextField("X", value: objectPosition(axes: .x), format: .number)
			TextField("Y", value: objectPosition(axes: .y), format: .number)
			TextField("Z", value: objectPosition(axes: .z), format: .number)
		}
		.textFieldStyle(.roundedBorder)
		.keyboardType(.numbersAndPunctuation)
		.padding(32)
	}

	/// Returns a binding to a robot-space coordinate for a given axis.
	/// When the binding is modified, it:
	/// 1. Gets the current robot position by converting the local position.
	/// 2. Replaces the corresponding axis value with the new value.
	/// 3. Converts the updated robot position back to local space.
	/// 4. Updates the entity's local position.
	private func objectPosition(axes: Axes) -> Binding<Float> {
		Binding {
			guard let entity = appModel.selectedEntity else { return 0 }
			let local = entity.position
			let robot = calibrationManager.convertLocalToRobot(local: local)
			switch axes {
			case .x:
				return robot.x
			case .y:
				return robot.y
			case .z:
				return robot.z
			}
		} set: { newRobotValue in
			guard let entity = appModel.selectedEntity else { return }

			// Convert current local position to robot space.
			var currentRobot = calibrationManager.convertLocalToRobot(local: entity.position)

			// Replace the specific axis with the new value.
			switch axes {
			case .x:
				currentRobot.x = newRobotValue
			case .y:
				currentRobot.y = newRobotValue
			case .z:
				currentRobot.z = newRobotValue
			}

			// Convert the updated robot coordinate back to local space.
			let newLocal = calibrationManager.convertRobotToLocal(robot: currentRobot)
			entity.position = newLocal

			// Optionally, send a position update.
			connectionManager.sendPositionUpdate(for: entity, newPosition: currentRobot)
		}
	}
}

#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 280, height: 320)) {
	InspectorView()
		.environment(AppModel.shared)
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
