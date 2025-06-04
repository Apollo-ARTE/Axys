//
//  InfoMessage.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

import Foundation

/// Represents an informational or error message from Rhino.
struct InfoMessage: Codable {
    let type: String
    let description: String
    let timestamp: Double
}
