//
//  AxesComponent.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 23/05/25.
//

import RealityKit
import Observation

/// A component that stores which axes are allowed for position and rotation on an entity.
///
/// Use this component to restrict movement or rotation to specific axes.
/// By default, all axes (X, Y, Z) are allowed for both position and rotation.
@Observable
class AxesComponent: Component {
	var allowedPositionAxes: AxisOptions = .all
	var allowedRotationAxes: AxisOptions = .all
}
