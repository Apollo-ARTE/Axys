//
//  ModelEntity+RhinoObject.swift
//  Northstar
//
//  Created by Ilia Sedelkin on 15/04/25.
//

import RealityKit
import OSLog

extension ModelEntity {
    static func rhinoObject(name: String) async throws -> ModelEntity? {

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(name).usdz")

        guard let object = try? await ModelEntity(contentsOf: fileURL) else {
            Logger().info("Failed to load \(name)")
			return nil
		}
		object.components.set(InputTargetComponent())
		object.components.set(HoverEffectComponent())
		object.generateCollisionShapes(recursive: true)
		object.position = [0, 0, 0]

		return object
	}
}
