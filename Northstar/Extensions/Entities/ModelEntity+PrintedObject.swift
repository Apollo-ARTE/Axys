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

    static func robotReach() async throws -> ModelEntity? {
        guard let object = try? await ModelEntity(named: "robot_reach") else {
            return nil
        }
        object.name = "robot_reach_blue"
        object.transform.scale = [0, 0, 0]
        return object
    }

    static func virtualLab() async throws -> ModelEntity? {
        guard let object = try? await ModelEntity(named: "VirtualLab+Robot") else {
            return nil
        }
        object.name = "virtual_lab"
        object.transform.scale = [0, 0, 0]

        return object
    }
}
