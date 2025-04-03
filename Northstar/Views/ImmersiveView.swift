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
            if let model = try? await ModelEntity(named: "OriginModel") {
                model.generateCollisionShapes(recursive: false)
                model.components.set(InputTargetComponent())
                model.position = [0, 1.3, -1]
                rhinoConnectionManager.sphereEntity = model
                content.add(model)
            }
//            let mesh = MeshResource.generateSphere(radius: 0.03)
//            let sphere = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .red, isMetallic: false)])
//				sphere.generateCollisionShapes(recursive: false)
//				sphere.components.set(InputTargetComponent())
//				sphere.position = [0, 1.3, -1]
//				rhinoConnectionManager.sphereEntity = sphere
//				content.add(sphere)
//			}
		} update: { content, attachments in
//			if appModel.showModels {
//				if content.entities.first(where: { $0.name == "centerSphere" }) == nil {
//					content.add(imageTracking.centerEntity)
//				}
//			} else {
//				content.entities.removeAll(where: { $0.name == "centerSphere" })
//			}
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
        .environment(ImageTracking())
        .environment(RhinoConnectionManager())
}
