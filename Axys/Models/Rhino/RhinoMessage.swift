//
//  RhinoMessage.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation

struct BatchRhinoMessage: Codable {
    let type: String
    let objects: [RhinoMessage]
    let timestamp: Double
}

struct RhinoMessage: Codable {
    let type: String
    let objectName: String
    let objectId: String
    let center: Position
    let timestamp: Double
}

struct InfoMessage: Codable {
    let type: String
    let description: String
    let timestamp: Double
}
