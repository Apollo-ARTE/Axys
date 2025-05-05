//
//  Coordinate.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 26/03/25.
//

import Foundation
import RealityKit

class Coordinate {
	var robotX: Float
	var robotY: Float
	var robotZ: Float

	var localX: Float
	var localY: Float
	var localZ: Float

	init(robotX: Float = 0, robotY: Float = 0, robotZ: Float = 0, localX: Float = 0, localY: Float = 0, localZ: Float = 0) {
		self.robotX = robotX
		self.robotY = robotY
		self.robotZ = robotZ
		self.localX = localX
		self.localY = localY
		self.localZ = localZ
	}

	required init(from decoder: Decoder) throws {
		let container = try? decoder.container(keyedBy: CodingKeys.self)
		robotX = try container?.decodeIfPresent(Float.self, forKey: .robotX) ?? 0
		robotY = try container?.decodeIfPresent(Float.self, forKey: .robotY) ?? 0
		robotZ = try container?.decodeIfPresent(Float.self, forKey: .robotZ) ?? 0

		// Always reset local coords
		localX = 0
		localY = 0
		localZ = 0
	}
}

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

	func save(key: String) {
		if let encoded = try? JSONEncoder().encode(self) {
			UserDefaults.standard.set(encoded, forKey: key)
		}
	}

	static func load(key: String) -> Coordinate? {
		if let data = UserDefaults.standard.data(forKey: key),
		   let coordinate = try? JSONDecoder().decode(Coordinate.self, from: data) {
			return coordinate
		}
		return nil
	}
}
