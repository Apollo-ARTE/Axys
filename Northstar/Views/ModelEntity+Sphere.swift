//
//  ModelEntity+Sphere.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 14/03/25.
//

import RealityKit

extension ModelEntity {
	static func centerSphere() -> Entity {
		let mesh = MeshResource.generateBox(size: [0.13, 0.001, 0.13])
		let material = SimpleMaterial(color: .gray, isMetallic: true)
		let entity = ModelEntity(mesh: mesh, materials: [material])
		entity.components.set(InputTargetComponent())
		entity.generateCollisionShapes(recursive: true)
		return entity
	}

	static func movableSphere() -> ModelEntity {
		let sphere = ModelEntity(mesh: .generateBox(size: [0.13, 0.001, 0.13]), materials: [UnlitMaterial(color: .yellow)])
		sphere.components.set(InputTargetComponent())
		sphere.components.set(HoverEffectComponent())
		sphere.generateCollisionShapes(recursive: true)
		return sphere
	}

}
