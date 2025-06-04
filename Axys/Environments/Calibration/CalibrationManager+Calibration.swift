//
//  CalibrationManager+Calibration.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 22/05/25.
//

import Foundation
import RealityKit

extension CalibrationManager {
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
		calibrationStep = .placeMarkers
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

	func convertToSimdFloat3(from coordinate: Coordinate, zOffset: Double) -> simd_float3 {
		return simd_float3(
			Float(coordinate.robotX) / 1000,
			Float(coordinate.robotY) / 1000,
			Float(coordinate.robotZ) / 1000 - Float(zOffset) / 1000
		)
	}
}
