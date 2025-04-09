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
	@Environment(AppModel.self) private var appModel
	@Environment(ImageTrackingManager.self) private var imageTracking
	@Environment(RhinoConnectionManager.self) private var rhinoConnectionManager
	@Environment(CalibrationManager.self) private var calibrationManager

	@State private var rhinoObject = Entity()
	@State private var localCoordinates: SIMD3<Float> = .zero
	@State private var robotCoordinates: SIMD3<Float> = .zero
    
	var body: some View {
        RealityView { content, attachments in
			if let printedObject = try? await ModelEntity.rhinoObject(name: "print") {
				self.rhinoObject = printedObject
            }

			rhinoConnectionManager.object = rhinoObject

            // Optionally add an attachment to display coordinates.
            if let coordinatesAttachment = attachments.entity(for: "coordinates") {
                coordinatesAttachment.position = [0, 0.4, 0]
                rhinoObject.addChild(coordinatesAttachment)
            }

            content.add(rhinoObject)
            content.add(imageTracking.rootEntity)
		} update: { _, _ in
//			if calibrationManager.isCalibrationCompleted && !calibrationManager.didSetZeroPosition {
//				Logger.calibration.log("Setting zero position")
//				Logger.calibration.log("\(calibrationManager.convertRobotToLocal(robot: [0, 0, 0]))")
//				if let model = content.entities.first {
//					Logger.calibration.log("Entered here")
//					model.position = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
//				}
//
//				calibrationManager.didSetZeroPosition = true
//			}
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
		.onAppear {
			rhinoConnectionManager.connectToWebSocket()
		}
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

	/// Converts a measurement in meters to a formatted string in centimeters.
	func convertToCentimeters(meters: Float) -> String {
		let measurement = Measurement(value: Double(meters), unit: UnitLength.meters)
		let centimeters = measurement.converted(to: .centimeters)
		let formatter = MeasurementFormatter()
		formatter.unitOptions = .providedUnit
		return formatter.string(from: centimeters)
	}
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
        .environment(ImageTrackingManager())
		.environment(RhinoConnectionManager(calibrationManager: .init()))
        .environment(CalibrationManager())
}
