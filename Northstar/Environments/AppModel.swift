//
//  AppModel.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit

@MainActor
@Observable
class AppModel {
	static let shared: AppModel = .init()

	private init() {}

    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

	var showCalibrationWindow = false
	var showModels = false
	var showRobotReach = false

	var selectedEntity: Entity?
    var showVirtualLab = false

    let robotReachRoot = Entity()
    let virtualLabRoot = Entity()

    var allowedAxes: AxisOptions = .all

    var selectedMode: Mode = .position

    var rotationStore: [Entity: simd_quatf] = [:]

}
