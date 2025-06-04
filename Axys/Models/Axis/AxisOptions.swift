//
//  AxisOptions 2.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

struct AxisOptions: OptionSet {
    let rawValue: Int

    static let x = AxisOptions(rawValue: 1 << 0)
    static let y = AxisOptions(rawValue: 1 << 1)
    static let z = AxisOptions(rawValue: 1 << 2)

    static let xy: AxisOptions = [.x, .y]
    static let all: AxisOptions = [.x, .y, .z]

	mutating func toggle(_ axis: AxisOptions) {
		if contains(axis) {
			remove(axis)
		} else {
			insert(axis)
		}
	}
}
