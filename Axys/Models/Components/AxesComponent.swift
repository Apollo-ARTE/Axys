//
//  AxesComponent.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 23/05/25.
//

import RealityKit
import Observation

@Observable
class AxesComponent: Component {
	var allowedPositionAxes: AxisOptions = .all
	var allowedRotationAxes: AxisOptions = .all
}
