//
//  ImmersiveView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
import simd
import simd

struct ImmersiveView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(AppModel.self) private var appModel
    @Environment(ImageTrackingManager.self) private var imageTracking
    @Environment(RhinoConnectionManager.self) private var rhinoConnectionManager
    @Environment(CalibrationManager.self) private var calibrationManager

	@State private var rootObject = Entity()
    @State private var robotReachEntity = Entity()
    @State private var virtualLabEntity = Entity()
    @State private var localCoordinates: SIMD3<Float> = .zero
    @State private var robotCoordinates: SIMD3<Float> = .zero

	var body: some View {
        RealityView { content, _ in
            if let robotReachEntity = try? await ModelEntity.robotReach() {
                self.robotReachEntity = robotReachEntity
            }
            if let virtualLabEntity = try? await ModelEntity.virtualLab() {
                self.virtualLabEntity = virtualLabEntity
            }

            // // Optionally add an attachment to display coordinates.
            // if let coordinatesAttachment = attachments.entity(for: "coordinates") {
            //     coordinatesAttachment.position = [0, 0.4, 0]
            //     printedObject.addChild(coordinatesAttachment)
            // }

            content.add(appModel.robotReachRoot)
            content.add(appModel.virtualLabRoot)
            content.add(rhinoConnectionManager.rhinoRootEntity)
            content.add(imageTracking.rootEntity)
		} update: { content, _ in
            if appModel.showRobotReach && calibrationManager.isCalibrationCompleted {
                if let model = content.entities.first(where: { $0.name == "robot_reach_blue" }) {
                    model.position = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
                    model.transform.scale = [0.001, 0.001, 0.001]
                    }
            } else {
                if let model = content.entities.first(where: { $0.name == "robot_reach_blue" }) {
                    model.transform.scale = [0, 0, 0]
                }
            }

            if appModel.showModels && calibrationManager.isCalibrationCompleted {
                //            if appModel.showModels { // Uncomment line for testing without calibration
                if let model = content.entities.first(where: { $0.name == "rhino_root" }) {
                    model.children.forEach { rhinoObject in
                        rhinoObject.transform.scale = [0.001, 0.001, 0.001]
                        Logger.views.debug("Showing object: \(rhinoObject.name)")
                    }
                }
            } else {
                if let model = content.entities.first(where: { $0.name == "rhino_root" }) {
                    model.children.forEach { rhinoObject in
                        Logger.views.debug("Hiding object: \(rhinoObject.name)")
                        rhinoObject.transform.scale = [0, 0, 0]
                    }
                }
            }

            if appModel.showVirtualLab && calibrationManager.isCalibrationCompleted {
                if let model = content.entities.first(where: { $0.name == "virtual_lab" }) {
                    model.transform.scale = [0.001, 0.001, 0.001]
                    model.look(
                        at: calibrationManager.convertRobotToLocal(robot: [0, 10, 0]),
                        from: calibrationManager.convertRobotToLocal(robot: [0, 0, 0]),
                        relativeTo: nil)
                }
            } else {
                if let model = content.entities.first(where: { $0.name == "virtual_lab" }) {
                    model.transform.scale = [0, 0, 0]
                }
            }
        } attachments: {
            Attachment(id: "coordinates") {
                VStack {
                    HStack {
                        Text("Local:")
                        Text("X: \(convertToCentimeters(meters: localCoordinates.x))")
                        Text("Y: \(convertToCentimeters(meters: localCoordinates.y))")
                        Text("Z: \(convertToCentimeters(meters: localCoordinates.z))")
                    }
                    HStack {
                        Text("Robot:")
                        Text("X: \(convertToCentimeters(meters: robotCoordinates.x))")
                        Text("Y: \(convertToCentimeters(meters: robotCoordinates.y))")
                        Text("Z: \(convertToCentimeters(meters: robotCoordinates.z))")
                    }
                }
                .padding()
                .glassBackgroundEffect()
            }
        }
		.gesture(
			TapGesture()
				.targetedToAnyEntity()
				.onEnded { value in
					appModel.selectedEntity = value.entity
					openWindow(id: "inspector")
				}
		)
		.gesture(
			DragGesture()
				.targetedToAnyEntity()
				.onChanged { value in
					// Convert the gesture's location into the coordinate space of the entity's parent.
					if let parent = value.entity.parent {
						value.entity.position = value.convert(value.location3D, from: .local, to: parent)
					}

					// Update the local coordinate state.
					localCoordinates = value.entity.position

					// Convert the local coordinate to robot coordinate using the new calibration method.
					robotCoordinates = calibrationManager.convertLocalToRobot(local: value.entity.position)
				}
				.onEnded { value in
					let newPosition = calibrationManager.convertLocalToRobot(local: value.entity.position)
					// Send a position update.
					rhinoConnectionManager.sendPositionUpdate(for: value.entity, newPosition: newPosition)
					Logger.connection.info("Sending position update for local coordinates \(value.entity.position), and robot coordinates \(newPosition)")
				}
		)
	}

    func showObjects(content: RealityViewContent) {
        if let model = content.entities.first(where: { $0.name == "rhino_root" }) {
            model.children.forEach { rhinoObject in
                rhinoObject.transform.scale = [1, 1, 1]
            }
        }
    }

	/// Converts a measurement in meters to a formatted string in centimeters.
	func convertToCentimeters(meters: Float) -> String {
		let measurement = Measurement(value: Double(meters), unit: UnitLength.meters)
		let centimeters = measurement.converted(to: .centimeters)
		let formatter = MeasurementFormatter()
		formatter.unitOptions = .providedUnit
		return formatter.string(from: centimeters)
	}
        } attachments: {
            Attachment(id: "coordinates") {
                VStack {
                    HStack {
                        Text("Local:")
                        Text("X: \(localCoordinates.x.convertToMillimiters())")
                        Text("Y: \(localCoordinates.y.convertToMillimiters())")
                        Text("Z: \(localCoordinates.z.convertToMillimiters())")
                    }
                    HStack {
                        Text("Robot:")
                        Text("X: \(robotCoordinates.x.convertToMillimiters())")
                        Text("Y: \(robotCoordinates.y.convertToMillimiters())")
                        Text("Z: \(robotCoordinates.z.convertToMillimiters())")
                    }
                }
                .padding()
                .glassBackgroundEffect()
            }
        }
        .gesture(tapGesture())
        .simultaneousGesture(rotateGesture3D())
        .simultaneousGesture(dragGesture3D())
        .onChange(of: appModel.showRobotReach) { _, newValue in
            toggleRobotReachVisibility(isVisible: newValue)
        }
        .onChange(of: appModel.showVirtualLab) { _, newValue in
            toggleVirtualLabVisibility(isVisible: newValue)
        }
    }

    private func toggleRobotReachVisibility(isVisible: Bool) {
        if isVisible && calibrationManager.isCalibrationCompleted {
            let position = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
            appModel.robotReachRoot.position = position
            appModel.robotReachRoot.addChild(robotReachEntity)
        } else {
            robotReachEntity.removeFromParent()
        }
    }

    private func toggleVirtualLabVisibility(isVisible: Bool) {
        if isVisible && calibrationManager.isCalibrationCompleted {
            let target = calibrationManager.convertRobotToLocal(robot: [0, 10, 0])
            let from = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
            appModel.virtualLabRoot.look(at: target, from: from, relativeTo: nil)
            appModel.virtualLabRoot.addChild(virtualLabEntity)
        } else {
            virtualLabEntity.removeFromParent()
        }
    }

    private func rotateGesture3D() -> some Gesture {
        RotateGesture3D()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let parent = value.entity.parent else { return }

                let baseQuat = appModel.rotationStore[value.entity] ?? {
                    let orientation = value.entity.orientation(relativeTo: parent)
                    appModel.rotationStore[value.entity] = orientation
                    return orientation
                }()

                let rawDelta = value.convert(value.rotation, from: .local, to: parent)
                let e = rawDelta.eulerAngles

                let ex = appModel.allowedRotationAxes.contains(.x) ? e.x : 0
                let ey = appModel.allowedRotationAxes.contains(.y) ? e.y : 0
                let ez = appModel.allowedRotationAxes.contains(.z) ? e.z : 0

                let filteredDelta = simd_quatf(angle: ez, axis: [0,0,1]) *
                                    simd_quatf(angle: ey, axis: [0,1,0]) *
                                    simd_quatf(angle: ex, axis: [1,0,0])

                value.entity.setOrientation(filteredDelta * baseQuat, relativeTo: parent)
            }
            .onEnded { value in
                guard let parent = value.entity.parent,
                      let baseQuat = appModel.rotationStore[value.entity]
                else { return }

                let rawDelta = value.convert(value.rotation, from: .local, to: parent)
                let e = rawDelta.eulerAngles

                let ex = appModel.allowedRotationAxes.contains(.x) ? e.x : 0
                let ey = appModel.allowedRotationAxes.contains(.y) ? e.y : 0
                let ez = appModel.allowedRotationAxes.contains(.z) ? e.z : 0

                let filteredDelta = simd_quatf(angle: ez, axis: [0,0,1]) *
                                    simd_quatf(angle: ey, axis: [0,1,0]) *
                                    simd_quatf(angle: ex, axis: [1,0,0])

                let finalQuat = filteredDelta * baseQuat
                value.entity.setOrientation(finalQuat, relativeTo: parent)
                appModel.rotationStore.removeValue(forKey: value.entity)
            }
    }

    private func dragGesture3D() -> some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let parent = value.entity.parent else { return }

                let newPos = value.convert(value.location3D, from: .local, to: parent)
                var current = value.entity.position

                if appModel.allowedPositionAxes.contains(.x) { current.x = newPos.x }
                if appModel.allowedPositionAxes.contains(.y) { current.y = newPos.y }
                if appModel.allowedPositionAxes.contains(.z) { current.z = newPos.z }

                value.entity.position = current

                localCoordinates = current
                robotCoordinates = calibrationManager.convertLocalToRobot(local: current)
            }
            .onEnded { value in
                let finalRobot = calibrationManager.convertLocalToRobot(local: value.entity.position)
                rhinoConnectionManager.sendPositionUpdate(for: value.entity, newPosition: finalRobot)
                Logger.connection.info("Sent pos update: local \(value.entity.position), robot \(finalRobot)")
            }
    }

    private func tapGesture() -> some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                appModel.selectedEntity = value.entity
                openWindow(id: "inspector")
            }
    }
}

#Preview(immersionStyle: .mixed) {
	ImmersiveView()
		.environment(AppModel.shared)
		.environment(ImageTrackingManager.init(calibrationManager: .shared))
		.environment(CalibrationManager.shared)
		.environment(RhinoConnectionManager(calibrationManager: .shared))
}
