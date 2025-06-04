//
//  Float+Conversion.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 30/04/25.
//

import Foundation

extension Float {
	/// Converts a measurement in meters to a formatted string in millimiters.
	func convertToMillimiters() -> String {
		let measurement = Measurement(value: Double(self), unit: UnitLength.meters)
		let convertedMeasurement = measurement.converted(to: .millimeters)
		return convertedMeasurement.formatted(
			.measurement(
				width: .narrow,
				usage: .asProvided,
				numberFormatStyle: .number.precision(.fractionLength(0))
			)
		)
	}
}
