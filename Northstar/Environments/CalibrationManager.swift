//
//  CalibrationManager.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import Foundation
import simd
import RealityFoundation
import OSLog

@Observable
class CalibrationManager {
	var coordinates1 = Coordinate()
	var coordinates2 = Coordinate()
	var coordinates3 = Coordinate()

	private var rotationMatrix: matrix_float3x3?
	private var translationVector: SIMD3<Float>?

	func computeTransformation() -> Bool {
		let localPoints: [SIMD3<Float>] = [
			SIMD3(coordinates1.localX, coordinates1.localY, coordinates1.localZ),
			SIMD3(coordinates2.localX, coordinates2.localY, coordinates2.localZ),
			SIMD3(coordinates3.localX, coordinates3.localY, coordinates3.localZ)
		]
		let robotPoints: [SIMD3<Float>] = [
			SIMD3(coordinates1.robotX, coordinates1.robotY, coordinates1.robotZ),
			SIMD3(coordinates2.robotX, coordinates2.robotY, coordinates2.robotZ),
			SIMD3(coordinates3.robotX, coordinates3.robotY, coordinates3.robotZ)
		]

		let localCentroid = localPoints.reduce(SIMD3<Float>(0, 0, 0), { $0 + $1 }) / 3.0
		let robotCentroid = robotPoints.reduce(SIMD3<Float>(0, 0, 0), { $0 + $1 }) / 3.0

		let centeredLocal = localPoints.map { $0 - localCentroid }
		let centeredRobot = robotPoints.map { $0 - robotCentroid }

		var H = matrix_float3x3(0)
		for i in 0..<3 {
			let cl = centeredLocal[i]
			let cr = centeredRobot[i]
			H += matrix_float3x3(rows: [
				SIMD3(cl.x * cr.x, cl.x * cr.y, cl.x * cr.z),
				SIMD3(cl.y * cr.x, cl.y * cr.y, cl.y * cr.z),
				SIMD3(cl.z * cr.x, cl.z * cr.y, cl.z * cr.z)
			])
		}

		guard let svd = H.svd() else { return false }
		let U = svd.U
		let V = svd.V

		var R = V * U.transpose

		if R.determinant < 0 {
			var adjustedV = V
			adjustedV.columns.2 = -adjustedV.columns.2
			R = adjustedV * U.transpose
		}

		let T = robotCentroid - R * localCentroid

		rotationMatrix = R
		translationVector = T

		return true
	}

	func localToRobot(localPoint: SIMD3<Float>) -> SIMD3<Float>? {
		guard let R = rotationMatrix, let T = translationVector else { return nil }
		return R * localPoint + T
	}

	func robotToLocal(robotPoint: SIMD3<Float>) -> SIMD3<Float>? {
		guard let R = rotationMatrix, let T = translationVector else { return nil }
		let invR = R.transpose
		return invR * (robotPoint - T)
	}
}

// MARK: - SVD for 3x3 Matrix
extension matrix_float3x3 {
	var determinant: Float {
		let col0 = self.columns.0
		let col1 = self.columns.1
		let col2 = self.columns.2
		let a = col0.x, b = col1.x, c = col2.x
		let d = col0.y, e = col1.y, f = col2.y
		let g = col0.z, h = col1.z, i = col2.z
		return a*(e*i - f*h) - b*(d*i - f*g) + c*(d*h - e*g)
	}

	func svd() -> (U: matrix_float3x3, S: matrix_float3x3, V: matrix_float3x3)? {
		// This is a simplified SVD implementation for 3x3 matrices.
		// For production, consider using a robust numerical library.
		var matrix = self
		var u = matrix_float3x3(1)
		var v = matrix_float3x3(1)
		var s = matrix_float3x3(0)

		// Iterative method for SVD (example placeholder)
		// Note: This is a placeholder and not numerically accurate.
		// In practice, use LAPACK or similar.
		for _ in 0..<10 {
			let (q1, r1) = matrix.decomposeQR()
			let (q2, r2) = r1.transpose.decomposeQR()
			matrix = r2.transpose
			u *= q1
			v = q2.transpose * v
		}

		s.columns.0.x = matrix.columns.0.x
		s.columns.1.y = matrix.columns.1.y
		s.columns.2.z = matrix.columns.2.z

		return (u, s, v)
	}

	private func decomposeQR() -> (Q: matrix_float3x3, R: matrix_float3x3) {
		// Placeholder QR decomposition
		// For real use, implement Householder reflections or Gram-Schmidt
		return (matrix_float3x3(1), self)
	}
}
