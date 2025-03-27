//
//  CalibrationManager.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import Foundation

@Observable
class CalibrationManager {
	var coordinates1 = (robot: Coordinate.init(), local: Coordinate.init())
	var coordinates2 = (robot: Coordinate.init(), local: Coordinate.init())
	var coordinates3 = (robot: Coordinate.init(), local: Coordinate.init())
}
