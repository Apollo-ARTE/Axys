//
//  BatchRhinoMessage.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

import Foundation

/// Represents a batch message containing multiple Rhino objects.
struct BatchRhinoMessage: Codable {
    let type: String
    let objects: [RhinoMessage]
    let timestamp: Double
}
