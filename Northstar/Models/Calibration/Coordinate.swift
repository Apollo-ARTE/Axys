//
//  Coordinate.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 26/03/25.
//

import Foundation

class Coordinate {
	var robotX: String
	var robotY: String
	var robotZ: String

	var localX: String
	var localY: String
	var localZ: String

	init(robotX: String = "", robotY: String = "", robotZ: String = "", localX: String = "", localY: String = "", localZ: String = "") {
		self.robotX = robotX
		self.robotY = robotY
		self.robotZ = robotZ
		self.localX = localX
		self.localY = localY
		self.localZ = localZ
	}
}
