//
//  ModelEntity+VirtualLab.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

import RealityKit

extension ModelEntity {
	static func virtualLab() async throws -> ModelEntity? {
		guard let object = try? await ModelEntity(named: "virtual_lab") else {
			return nil
		}

		object.name = "virtual_lab"
		return object
	}
}
