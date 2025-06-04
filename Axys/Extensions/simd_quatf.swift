//
//  simd_quatf.swift
//  Axys
//
//  Created by Guillermo Kramsky on 06/05/25.
//

import simd

extension simd_quatf {
    /// Returns intrinsic XYZ (Tait–Bryan) Euler angles (in radians).
    var eulerAngles: SIMD3<Float> {
        let q = normalized

        // roll (x-axis rotation)
        let sinr_cosp = 2 * (q.real * q.imag.x + q.imag.y * q.imag.z)
        let cosr_cosp = 1 - 2 * (q.imag.x * q.imag.x + q.imag.y * q.imag.y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        // pitch (y-axis rotation)
        let sinp = 2 * (q.real * q.imag.y - q.imag.z * q.imag.x)
        let pitch: Float
        if abs(sinp) >= 1 {
            pitch = copysign(.pi/2, sinp)
        } else {
            pitch = asin(sinp)
        }

        // yaw (z-axis rotation)
        let siny_cosp = 2 * (q.real * q.imag.z + q.imag.x * q.imag.y)
        let cosy_cosp = 1 - 2 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        return SIMD3(roll, pitch, yaw)
    }
}
