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
	@Environment(ImageTracking.self) private var imageTracking

    var body: some View {
		RealityView { content, attachments in
			content.add(imageTracking.rootEntity)
			imageTracking.sphere = ModelEntity.movableSphere()
			imageTracking.rootEntity.addChild(imageTracking.sphere)

			if let attachment = attachments.entity(for: "coordinates") {
				attachment.position = [0, 0.05, 0]
				imageTracking.sphere.addChild(attachment)
			}
		} update: { content, attachments in
		} attachments: {
			Attachment(id: "coordinates") {
				HStack {
					Text("X: \(convertToMeters(meters: imageTracking.modelPosition.x))")
					Text("Y: \(convertToMeters(meters: imageTracking.modelPosition.y))")
					Text("Z: \(convertToMeters(meters: imageTracking.modelPosition.z))")
				}
				.padding()
				.glassBackgroundEffect()
			}
		}
		.gesture(
			DragGesture()
				.targetedToEntity(imageTracking.sphere)
				.onChanged { value in
					value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
					let centerSphere = imageTracking.rootEntity.findEntity(named: "centerSphere")
					print("Spere: \(centerSphere)")
					imageTracking.modelPosition = imageTracking.sphere.position(relativeTo: centerSphere!)
				}
		)
    }

	func convertToMeters(meters: Float)-> String {

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
