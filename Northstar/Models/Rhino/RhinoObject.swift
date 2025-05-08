//
//  RhinoObject.swift
//  Northstar
//
//  Created by Ilia Sedelkin on 28/04/25.
//

import Foundation

struct RhinoObject: Codable {
    let objectId: String
    var objectName: String
    var rhinoPosition: SIMD3<Float>
}
