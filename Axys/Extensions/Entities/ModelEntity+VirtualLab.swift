//
//  ModelEntity+VirtualLab.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

import RealityFoundation

extension ModelEntity {
	static func virtualLab() async throws -> ModelEntity? {
		guard let object = try? await ModelEntity(named: "virtual_lab_empty") else {
			return nil
		}
		object.name = "virtual_lab"
		object.transform.scale = [0.001, 0.001, 0.001]

		return object
	}
}
