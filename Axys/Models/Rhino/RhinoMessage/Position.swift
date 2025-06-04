//
//  Position.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation

/// Represents a 3D position coordinate send from Rhino.
struct Position: Codable {
    let x: Double
    let y: Double
    let z: Double
}
