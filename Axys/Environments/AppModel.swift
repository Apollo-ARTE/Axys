//
//  AppModel.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit

/// A singleton model representing global application state.
///
/// `AppModel` is responsible for storing UI state, entity selections, and
/// root entities for various scene components. This shared model allows
/// multiple parts of the app to access and modify shared state.
@MainActor
@Observable
class AppModel {

	static let shared: AppModel = .init()

	private init() {}

	let immersiveSpaceID = "ImmersiveSpace"

	/// Represents the current state of the immersive space.
	enum ImmersiveSpaceState {
		case closed
		case inTransition
		case open
	}

	/// Tracks the current state of the immersive space.
	var immersiveSpaceState = ImmersiveSpaceState.closed

	/// Indicates whether calibration mode is enabled.
	var useCalibration = false

	/// Indicates whether Rhino 3D models are shown.
	var showModels = false
	/// Indicates whether the robot's reach visualization is shown.
	var showRobotReach = false
	/// Indicates whether the virtual lab environment should be shown.
	var showVirtualLab = false

	/// Tracks WebSocket or network connection status.
	var isConnected = false
	/// Currently selected entities for open inspectors.
	var selectedEntities: [Entity] = []

	/// Root entity for displaying the robot's reachable area.
	let robotReachRoot = Entity()
	/// Root entity for placing the virtual lab environment.
	let virtualLabRoot = Entity()

	/// Stores original rotations for entities (useful for transformation resets).
	var rotationStore: [Entity: simd_quatf] = [:]
}
