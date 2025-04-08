//
//  ModelEntity+PritedObject.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 08/04/25.
//

import RealityKit

extension ModelEntity {
	static func printedObject() async throws -> ModelEntity? {
		guard let object = try? await ModelEntity(named: "print") else {
			return nil
		}
		object.components.set(InputTargetComponent())
		object.components.set(HoverEffectComponent())
		object.generateCollisionShapes(recursive: true)
		object.position = [0, 0, 0]

		return object
	}
}
