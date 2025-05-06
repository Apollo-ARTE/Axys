//
//  Coordinate+Codable.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 05/05/25.
//

import Foundation

extension Coordinate: Codable {
	enum CodingKeys: String, CodingKey {
		case robotX, robotY, robotZ
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(robotX, forKey: .robotX)
		try container.encode(robotY, forKey: .robotY)
		try container.encode(robotZ, forKey: .robotZ)
	}
}
