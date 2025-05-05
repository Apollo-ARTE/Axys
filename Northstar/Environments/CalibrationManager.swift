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
	var marker1 = Coordinate(robotX: 0, robotY: 0, robotZ: 0, localX: 0, localY: 0, localZ: 0)
	var marker2 = Coordinate(robotX: 0, robotY: 0, robotZ: 0, localX: 0, localY: 0, localZ: 0)
	var marker3 = Coordinate(robotX: 0, robotY: 0, robotZ: 0, localX: 0, localY: 0, localZ: 0)

	var calibrationStep: CalibrationStep = .placeMarkers

	var isCalibrationCompleted = false
	var didSetZeroPosition = false
	// Transformation from local (Vision Pro) to robot coordinates.
	// 'rotation' is a 3x3 rotation matrix and 'translation' is a 3D translation vector.
	private var rotation = simd_float3x3(1) // Identity matrix as default.
	private var translation = simd_float3(0, 0, 0)

	/// Computes the rigid (rotation + translation) transform that maps local (Vision Pro) coordinates to robot coordinates.
	/// It uses the three markers stored in the class.
	func calibrate() {
		// Convert marker coordinates to simd_float3 for math operations.
		let v1 = simd_float3(marker1.localX, marker1.localY, marker1.localZ)
		let v2 = simd_float3(marker2.localX, marker2.localY, marker2.localZ)
		let v3 = simd_float3(marker3.localX, marker3.localY, marker3.localZ)

		let r1 = convertToSimdFloat3(from: marker1, zOffset: zOffset)
		let r2 = convertToSimdFloat3(from: marker2, zOffset: zOffset)
		let r3 = convertToSimdFloat3(from: marker3, zOffset: zOffset)

		// --- Construct an orthonormal basis for the local (Vision Pro) coordinate system ---
		let a1 = v2 - v1
		let a2 = v3 - v1

		let e1 = simd_normalize(a1)
		let u2 = a2 - simd_dot(a2, e1) * e1   // Remove the component along e1.
		let e2 = simd_normalize(u2)
		let e3 = simd_normalize(simd_cross(e1, e2)) // Perpendicular to both e1 and e2.

		// --- Construct an orthonormal basis for the robot coordinate system ---
		let b1 = r2 - r1
		let b2 = r3 - r1

		let f1 = simd_normalize(b1)
		let u4 = b2 - simd_dot(b2, f1) * f1   // Remove the component along f1.
		let f2 = simd_normalize(u4)
		let f3 = simd_normalize(simd_cross(f1, f2))

		// --- Determine the rotation matrix ---
		// Build matrices whose columns are the basis vectors.
		let E = simd_float3x3(columns: (e1, e2, e3))
		let F = simd_float3x3(columns: (f1, f2, f3))
		var Rmat = F * simd_transpose(E)   // This rotates vectors from the local to the robot frame.

		// Correct for potential reflection: if the determinant is negative, flip one axis.
		if simd_determinant(Rmat) < 0 {
			let Ffixed = simd_float3x3(columns: (f1, f2, -f3))
			Rmat = Ffixed * simd_transpose(E)
		}

		rotation = Rmat

		// --- Compute the translation ---
		// We require that the transform satisfies: r1 = R * v1 + t. Therefore:
		translation = r1 - Rmat * v1

		isCalibrationCompleted = true
	}

	/// Converts a point from the local (Vision Pro) coordinate system to the robot coordinate system.
	/// - Parameter local: A simd_float3 representing a point in local coordinates.
	/// - Returns: The corresponding point in robot coordinates.
	func convertLocalToRobot(local: simd_float3) -> simd_float3 {
		return rotation * local + translation
	}

	/// Converts a point from the robot coordinate system to the local (Vision Pro) coordinate system.
	/// - Parameter robot: A simd_float3 representing a point in robot coordinates.
	/// - Returns: The corresponding point in local coordinates.
	func convertRobotToLocal(robot: simd_float3) -> simd_float3 {
		// Since rotation is orthonormal, the inverse is the transpose.
		return simd_transpose(rotation) * (robot - translation)
	}

	// Convenience functions to work with the Coordinate class.

	/// Converts a Coordinate’s local values to robot coordinates.
	/// - Parameter coordinate: The Coordinate instance containing a local position.
	/// - Returns: A new Coordinate with robot values updated.
	func convertLocalToRobot(coordinate: Coordinate) -> Coordinate {
		let local = simd_float3(coordinate.localX, coordinate.localY, coordinate.localZ)
		let robot = convertLocalToRobot(local: local)
		return Coordinate(
			robotX: robot.x,
			robotY: robot.y,
			robotZ: robot.z,
			localX: coordinate.localX,
			localY: coordinate.localY,
			localZ: coordinate.localZ
		)
	}

	/// Converts a Coordinate’s robot values back to local (Vision Pro) coordinates.
	/// - Parameter coordinate: The Coordinate instance containing a robot position.
	/// - Returns: A new Coordinate with local values updated.
	func convertRobotToLocal(coordinate: Coordinate) -> Coordinate {
		let robot = simd_float3(coordinate.robotX, coordinate.robotY, coordinate.robotZ)
		let local = convertRobotToLocal(robot: robot)
		return Coordinate(
			robotX: coordinate.robotX,
			robotY: coordinate.robotY,
			robotZ: coordinate.robotZ,
			localX: local.x,
			localY: local.y,
			localZ: local.z
		)
	}

	/// Optionally, retrieve the full 4×4 transformation matrix from local to robot coordinates.
	/// This can be useful for interfacing with graphics or robotics APIs.
	func visionToRobotMatrix() -> simd_float4x4 {
		var transform = simd_float4x4(1)  // Identity matrix.
		transform.columns.0 = simd_float4(rotation.columns.0, 0)
		transform.columns.1 = simd_float4(rotation.columns.1, 0)
		transform.columns.2 = simd_float4(rotation.columns.2, 0)
		transform.columns.3 = simd_float4(translation, 1)
		return transform
	}

	func convertToSimdFloat3(from coordinate: Coordinate, zOffset: Double) -> simd_float3 {
		return simd_float3(
			Float(coordinate.robotX) / 1000,
			Float(coordinate.robotY) / 1000,
			Float(coordinate.robotZ) / 1000 - Float(zOffset)
		)
	}
}
