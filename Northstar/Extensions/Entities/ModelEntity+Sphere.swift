//
//  ModelEntity+Sphere.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 14/03/25.
//

import RealityKit
import UIKit

extension ModelEntity {
	static func movableSphere() -> ModelEntity {
		let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [UnlitMaterial(color: .white)])
		sphere.components.set(InputTargetComponent())
		sphere.components.set(HoverEffectComponent())
		sphere.generateCollisionShapes(recursive: true)
		sphere.name = "movableSphere"
		return sphere
	}
}
