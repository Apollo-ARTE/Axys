//
//  RhinoMessage.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation

struct RhinoMessage: Codable {
    let type: String
    let objectId: String
    let center: Position
    let radius: Double
    let timestamp: Double
}
