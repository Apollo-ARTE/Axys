//
//  ModelEntity+RhinoObject.swift
//  Northstar
//
//  Created by Ilia Sedelkin on 15/04/25.
//

import RealityKit

extension ModelEntity {
    static func rhinoObject(name: String) async throws -> ModelEntity? {
		guard let object = try? await ModelEntity(named: name) else {
			return nil
		}
		object.components.set(InputTargetComponent())
		object.components.set(HoverEffectComponent())
		object.generateCollisionShapes(recursive: true)
		object.position = [0, 0, 0]

		return object
	}
}
