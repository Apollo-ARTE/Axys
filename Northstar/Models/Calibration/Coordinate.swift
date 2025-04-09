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
}
