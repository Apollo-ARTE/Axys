//
//  InspectorView.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 08/04/25.
//

import SwiftUI
import RealityKit

struct InspectorView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(RhinoConnectionManager.self) private var connectionManager
    @Environment(CalibrationManager.self) private var calibrationManager

	@State var selectedMode: SegmentedMode = .position

	@Binding var entityID: String?
	var entity: Entity? {
		guard let entityID else { return nil }
		return appModel.selectedEntities.first { String($0.id) == entityID }
	}

	@State private var opacity: Double = 1

    var body: some View {
        @Bindable var connectionManager = connectionManager
		VStack(spacing: 16) {
			Text(entity?.components[NameComponent.self]?.objectName ?? "Unnamed Object")
                .font(.title2)

			VStack(alignment: .leading) {
				Text("Opacity")
					.font(.headline)
				Slider(value: $opacity) {
					Label("Opacity", systemImage: "lightspectrum.horizontal")
				}
			}

			VStack(alignment: .leading) {
				Text("Transform")
					.font(.headline)
				Picker("", selection: Binding<SegmentedMode>(
					get: { selectedMode },
					set: { selectedMode = $0 }
				)) {
					Label("Position", systemImage: "move.3d")
						.tag(SegmentedMode.position)
					Label("Rotation", systemImage: "rotate.3d.fill")
						.tag(SegmentedMode.rotation)
				}
				.pickerStyle(.segmented)
				.labelStyle(.iconOnly)

				ForEach(Axes.allCases) { axis in
					AxisControl(
						axis: axis,
						allowedAxes: allowedAxesBinding(),
						position: valueBinding(for: axis)
					)
				}
			}
        }
        .textFieldStyle(.roundedBorder)
        .keyboardType(.numbersAndPunctuation)
        .padding(32)
		.onDisappear {
			appModel.selectedEntities.removeAll(where: { String($0.id) == entityID ?? "" })
		}
    }

	/// Returns a binding to a robot-space coordinate for a given axis.
	/// When the binding is modified, it:
	/// 1. Gets the current robot position by converting the local position.
	/// 2. Replaces the corresponding axis value with the new value.
	/// 3. Converts the updated robot position back to local space.
	/// 4. Updates the entity's local position.
	private func objectPosition(axes: Axes) -> Binding<Float> {
		Binding {
			guard let entity else { return 0 }
			let local = entity.position
			let robot = calibrationManager.convertLocalToRobot(local: local)
			switch axes {
			case .x:
				return robot.x * 1000
			case .y:
				return robot.y * 1000
			case .z:
				return robot.z * 1000
			}
		} set: { newRobotValue in
			guard let entity else { return }

            // Convert current local position to robot space.
            var currentRobot = calibrationManager.convertLocalToRobot(local: entity.position)

			// Replace the specific axis with the new value.
			switch axes {
			case .x:
				currentRobot.x = newRobotValue / 1000
			case .y:
				currentRobot.y = newRobotValue / 1000
			case .z:
				currentRobot.z = newRobotValue / 1000
			}

            // Convert the updated robot coordinate back to local space.
            let newLocal = calibrationManager.convertRobotToLocal(robot: currentRobot)
            entity.position = newLocal

            // Optionally, send a position update.
            connectionManager.sendPositionUpdate(for: entity, newPosition: currentRobot)
        }
    }

    private func objectRotation(axes: Axes) -> Binding<Float> {
        Binding {
            guard let entity,
                  let parent = entity.parent else {
                return 0
            }
            // Decompose to Euler, convert to degrees
            let quat   = entity.orientation(relativeTo: parent)
            let angles = quat.eulerAngles * (180 / .pi)
            switch axes {
            case .x: return angles.x
            case .y: return angles.y
            case .z: return angles.z
            }
        } set: { newDegrees in
            guard let entity,
                  let parent = entity.parent else {
                return
            }
            // Read current quaternion → Euler (radians)
            var e = entity.orientation(relativeTo: parent).eulerAngles
            // Replace just the one component
            let newRad = newDegrees * (.pi / 180)
            switch axes {
            case .x: e.x = newRad
            case .y: e.y = newRad
            case .z: e.z = newRad
            }
            // Rebuild intrinsic XYZ quaternion
            let qx = simd_quatf(angle: e.x, axis: SIMD3(1,0,0))
            let qy = simd_quatf(angle: e.y, axis: SIMD3(0,1,0))
            let qz = simd_quatf(angle: e.z, axis: SIMD3(0,0,1))
            let newQuat = qz * qy * qx

            // Apply & notify
            entity.setOrientation(newQuat, relativeTo: parent)

            // MARK: TO DO
            //             connectionManager.sendRotationUpdate(for: entity, newOrientation: newQuat)
        }
    }

    private func valueBinding(for axis: Axes) -> Binding<Float> {
        switch selectedMode {
        case .position:
            return objectPosition(axes: axis)
        case .rotation:
            return objectRotation(axes: axis)
        }
    }

    private func allowedAxesBinding() -> Binding<AxisOptions> {
        Binding(get: {
			guard let allowedPositionAxes = entity?.components[AxesComponent.self]?.allowedPositionAxes,
					let allowedRotationAxes = entity?.components[AxesComponent.self]?.allowedRotationAxes else {
				return .all
			}

            return selectedMode == .position ? allowedPositionAxes : allowedRotationAxes
        }, set: { newValue in
            if selectedMode == .position {
				entity?.components[AxesComponent.self]?.allowedPositionAxes = newValue
            } else {
				entity?.components[AxesComponent.self]?.allowedRotationAxes = newValue
            }
        })
    }
}

#Preview(windowStyle: .automatic) {
	InspectorView(entityID: .constant(""))
		.environment(AppModel.shared)
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
        .environment(CalibrationManager.shared)
}
