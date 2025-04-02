//
//  ImmersiveView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
	@Environment(AppModel.self) private var appModel
	@Environment(ImageTrackingManager.self) private var imageTracking
	@Environment(RhinoConnectionManager.self) private var rhinoConnectionManager
	@Environment(CalibrationManager.self) private var calibrationManager

	@State private var movableSphere = Entity()
	@State private var localCoordinates: SIMD3<Float> = .zero
	@State private var robotCoordinates: SIMD3<Float> = .zero

	var body: some View {
		RealityView { content, attachments in
			// Create a movable sphere entity.
			let sphere = ModelEntity.movableSphere(color: .white)
			sphere.position = [0, 0, 0]
			movableSphere = sphere
			rhinoConnectionManager.sphereEntity = sphere

			// Optionally add an attachment to display coordinates.
			if let coordinatesAttachment = attachments.entity(for: "movableSphere") {
				coordinatesAttachment.position = [0, -0.1, 0]
				movableSphere.addChild(coordinatesAttachment)
			}

			content.add(sphere)
			content.add(imageTracking.rootEntity)
		} update: { content, attachments in
			// Optionally update content if needed.
		} attachments: {
			Attachment(id: "movableSphere") {
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
			DragGesture()
				.targetedToAnyEntity()
				.onChanged { value in
					// Convert the gesture's location into the coordinate space of the entity's parent.
					if let parent = value.entity.parent {
						value.entity.position = value.convert(value.location3D, from: .local, to: parent)
					}

					// Send a position update.
					rhinoConnectionManager.sendPositionUpdate(for: value.entity)

					// Update the local coordinate state.
					localCoordinates = value.entity.position

					// Convert the local coordinate to robot coordinate using the new calibration method.
					robotCoordinates = calibrationManager.convertLocalToRobot(local: value.entity.position)
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
}
