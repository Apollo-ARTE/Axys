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
	@Environment(RhinoConnectionManager.self) var rhinoConnectionManager

	var body: some View {
		RealityView { content in
			let sphere = ModelEntity.movableSphere(color: .white)
			rhinoConnectionManager.sphereEntity = sphere
			content.add(sphere)
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
