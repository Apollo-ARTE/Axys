//
//  RhinoMessage.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation

/// Represents data about a single Rhino object.
struct RhinoMessage: Codable {
    let type: String
    let objectName: String
    let objectId: String
    let center: Position
    let timestamp: Double
}
