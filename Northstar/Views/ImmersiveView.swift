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

	var body: some View {
		RealityView { content, attachments in
			let sphere = ModelEntity.movableSphere(color: .white)
			sphere.position = [0, 0, 0]
			movableSphere = sphere
			rhinoConnectionManager.sphereEntity = sphere

			if let coordinatesAttachment = attachments.entity(for: "movableSphere") {
				coordinatesAttachment.position = [0, -0.1, 0]
				movableSphere.addChild(coordinatesAttachment)
			}

			content.add(sphere)
			content.add(imageTracking.rootEntity)
		} update: { content, attachments in

		} attachments: {
			Attachment(id: "movableSphere") {
				VStack {
					Text(movableSphere.position.description)
					Text(calibrationManager.localToRobot(localPoint: movableSphere.position)?.description ?? "")
				}
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
					value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
					rhinoConnectionManager.sendPositionUpdate(for: value.entity)
				}
		)
	}

	func convertToMeters(meters: Float) -> String {
		let formatter = MeasurementFormatter()

		var distanceInMeters = Measurement(value: Double(meters), unit: UnitLength.meters)

		distanceInMeters.convert(to: UnitLength.centimeters)
		formatter.unitOptions = .providedUnit

		return formatter.string(from: distanceInMeters)
	}
}

#Preview(immersionStyle: .mixed) {
	ImmersiveView()
		.environment(AppModel())
}
