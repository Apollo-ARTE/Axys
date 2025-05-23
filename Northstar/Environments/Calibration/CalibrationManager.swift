//
//  CalibrationManager.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import Foundation
import SwiftUI
import simd
import RealityFoundation
import OSLog

/// Manages the calibration and coordinate conversion between the Vision Pro (local) and ABB robot systems.
/// It uses three markers (non-collinear points) to compute a 3D rigid transformation.
@Observable
class CalibrationManager {
	static let shared: CalibrationManager = .init()

	private init() {}

	// The z axes difference between Rhino's origin and the robot's origin
	@ObservationIgnored
	@AppStorage("zOffset")
	var zOffset: Double = 900

	// Markers with known coordinates in both systems.
	var marker1 = Coordinate.load(key: "marker1") ?? .init()
	var marker2 = Coordinate.load(key: "marker2") ?? .init()
	var marker3 = Coordinate.load(key: "marker3") ?? .init()

	var calibrationStep: CalibrationStep = .placeMarkers
    var isCalibrationCompleted = false

    // Transformation from local (Vision Pro) to robot coordinates.
    // 'rotation' is a 3x3 rotation matrix and 'translation' is a 3D translation vector.
    var rotation = simd_float3x3(1) // Identity matrix as default.
	var translation = simd_float3(0, 0, 0)

//	func reset() {
//		calibrationStep = .placeMarkers
//		isCalibrationCompleted = false
//	}
}
