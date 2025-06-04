//
//  RhinoObject.swift
//  Axys
//
//  Created by Ilia Sedelkin on 28/04/25.
//

import Foundation

/// Represents a Rhino object used internally with a 3D position.
struct RhinoObject: Codable, Hashable {
    let objectId: String
    var objectName: String
    var rhinoPosition: SIMD3<Float>
	var importDate: Date = .now
}
