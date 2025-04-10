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
	@Environment(ImageTracking.self) private var imageTracking
	@Environment(RhinoConnectionManager.self) var rhinoConnectionManager

	var body: some View {
		RealityView { content, attachments in
//			if appModel.showModels {
//				content.add(imageTracking.centerEntity)
//				if let attachment = attachments.entity(for: "coordinates") {
//					attachment.position = [0, 0.05, 0]
//					imageTracking.movableEntity.addChild(attachment)
//				}

//				let mesh = MeshResource.generateSphere(radius: 0.01)
//				let sphere = ModelEntity(mesh: mesh)
//				sphere.generateCollisionShapes(recursive: false)
//				sphere.components.set(InputTargetComponent())
//				sphere.position = [0, 1.3, -1]
//			}
} update: { content, attachments in
	print("🔄 [UPDATE] RealityView update triggered")
	print("🔎 [STATE] importedEntity: \(String(describing: rhinoConnectionManager.importedEntity))")
	print("📦 [STATE] Entities in content: \(content.entities.count)")
	if let importedEntity = rhinoConnectionManager.importedEntity,
	   content.entities.contains(importedEntity) == false {
		print("📍 [ACTION] Trying to add imported entity to scene")
		importedEntity.position = SIMD3<Float>(x: 0, y: 1.2, z: -1)
		print("✅ [UPDATE] Setting position for imported entity: \(importedEntity.position)")
 
				let anchor = AnchorEntity(world: .zero)
				anchor.addChild(importedEntity)
				content.add(anchor)
				print("✅ [UPDATE] Adding imported entity to scene content via anchor.")
			}
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
		.onAppear(perform: {
			rhinoConnectionManager.connectToWebSocket()
		})
		.gesture(
			DragGesture()
//				.targetedToEntity(imageTracking.movableEntity)
				.targetedToAnyEntity()
				.onChanged { value in
					value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
					rhinoConnectionManager.sendPositionUpdate(for: value.entity)
//					imageTracking.modelPosition = imageTracking.movableEntity.position(relativeTo: imageTracking.centerEntity)
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
