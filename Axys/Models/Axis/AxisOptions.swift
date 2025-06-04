//
//  AxisOptions 2.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

/// Represents a set of axes for selection or manipulation in 3D space.
struct AxisOptions: OptionSet {
    let rawValue: Int

	/// The X-axis option.
	static let x = AxisOptions(rawValue: 1 << 0)

	/// The Y-axis option.
	static let y = AxisOptions(rawValue: 1 << 1)

	/// The Z-axis option.
	static let z = AxisOptions(rawValue: 1 << 2)

	/// Combined option for both X and Y axes.
	static let xy: AxisOptions = [.x, .y]

	/// Combined option for all three axes: X, Y, and Z.
	static let all: AxisOptions = [.x, .y, .z]

	/// Toggles the presence of the specified axis in the option set.
	///
	/// - Parameter axis: The axis to toggle.
	mutating func toggle(_ axis: AxisOptions) {
		if contains(axis) {
			remove(axis)
		} else {
			insert(axis)
		}
	}
}
