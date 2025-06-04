//
//  ModelEntity+MarkerSphere.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 14/03/25.
//

import RealityKit
import UIKit

extension ModelEntity {
	static func markerSphere() -> ModelEntity {
		let sphere = ModelEntity(
			mesh: .generateSphere(radius: 0.01),
			materials: [UnlitMaterial(color: .white)]
		)
		
		return sphere
	}
}
