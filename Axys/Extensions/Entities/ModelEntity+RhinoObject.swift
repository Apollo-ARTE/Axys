//
//  ModelEntity+RhinoObject.swift
//  Axys
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

		var object: ModelEntity
		do {
			object = try await ModelEntity(contentsOf: fileURL)
		} catch {
			Logger().info("File URL is \(fileURL)")
			Logger().info("Failed to load \(name)")
			Logger.calibration.info("Could not import model \(error.localizedDescription)")
			return nil
		}

		object.components.set(InputTargetComponent())
		object.components.set(HoverEffectComponent())
		object.generateCollisionShapes(recursive: true)
		object.position = [0, 0, 0]

		return object
	}
}
