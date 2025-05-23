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

	var useCalibration = false
	var showModels = false
	var showRobotReach = false
    var isConnected = false

	var selectedEntities: [Entity] = []
    var showVirtualLab = false

    let robotReachRoot = Entity()
    let virtualLabRoot = Entity()

    var rotationStore: [Entity: simd_quatf] = [:]
}
