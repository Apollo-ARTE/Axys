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

struct ImmersiveView: View {
	@Environment(\.openWindow) private var openWindow
	@Environment(AppModel.self) private var appModel
	@Environment(ImageTrackingManager.self) private var imageTracking
	@Environment(RhinoConnectionManager.self) private var rhinoConnectionManager
	@Environment(CalibrationManager.self) private var calibrationManager

	@State private var rootObject = Entity()
	@State private var printedObject = Entity()
    @State private var robotReachEntity = Entity()
    @State private var virtualLabEntity = Entity()
	@State private var localCoordinates: SIMD3<Float> = .zero
	@State private var robotCoordinates: SIMD3<Float> = .zero

	var body: some View {
		RealityView { content, attachments in
			if let printedObject = try? await ModelEntity.printedObject() {
				self.printedObject = printedObject
			}

			rhinoConnectionManager.object = printedObject

			// Optionally add an attachment to display coordinates.
			if let coordinatesAttachment = attachments.entity(for: "coordinates") {
				coordinatesAttachment.position = [0, 0.4, 0]
				printedObject.addChild(coordinatesAttachment)
			}

            if let robotReachEntity = try? await ModelEntity.robotReach() {
                self.robotReachEntity = robotReachEntity
            }
            if let virtualLabEntity = try? await ModelEntity.virtualLab() {
                self.virtualLabEntity = virtualLabEntity
            }

            content.add(appModel.robotReachRoot)
            content.add(appModel.virtualLabRoot)
            content.add(printedObject)
            content.add(imageTracking.rootEntity)
		} attachments: {
			Attachment(id: "coordinates") {
				VStack {
					HStack {
						Text("Local:")
						Text("X: \(convertToMillimiters(millimiters: localCoordinates.x))")
						Text("Y: \(convertToMillimiters(millimiters: localCoordinates.y))")
						Text("Z: \(convertToMillimiters(millimiters: localCoordinates.z))")
					}
					HStack {
						Text("Robot:")
						Text("X: \(convertToMillimiters(millimiters: robotCoordinates.x))")
						Text("Y: \(convertToMillimiters(millimiters: robotCoordinates.y))")
						Text("Z: \(convertToMillimiters(millimiters: robotCoordinates.z))")
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
        .onChange(of: appModel.showRobotReach) { _, newValue in
            toggleRobotReachVisibility(isVisible: newValue)
        }
        .onChange(of: appModel.showVirtualLab) { _, newValue in
            toggleVirtualLabVisibility(isVisible: newValue)
        }
	}

	/// Converts a measurement in meters to a formatted string in centimeters.
	func convertToMillimiters(millimiters: Float) -> String {
		let measurement = Measurement(value: Double(millimiters), unit: UnitLength.millimeters)
		let formatter = MeasurementFormatter()
		formatter.unitOptions = .providedUnit
		return formatter.string(from: measurement)
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
}

#Preview(immersionStyle: .mixed) {
	ImmersiveView()
		.environment(AppModel.shared)
		.environment(ImageTrackingManager.init(calibrationManager: .shared))
		.environment(CalibrationManager.shared)
		.environment(RhinoConnectionManager(calibrationManager: .shared))
}
