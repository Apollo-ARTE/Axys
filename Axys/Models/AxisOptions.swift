//
//  AxesOptions.swift
//  Northstar
//
//  Created by Guillermo Kramsky on 05/05/25.
//

import Foundation

enum Axes: CaseIterable, Identifiable {
    case x, y, z

    var id: Self { self }
    var label: String {
        switch self {
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        }
    }
    /// The corresponding bitmask value in your OptionSet
    var option: AxisOptions {
        switch self {
        case .x: return .x
        case .y: return .y
        case .z: return .z
        }
    }
}

enum SegmentedMode {
    case position, rotation
}

struct AxisOptions: OptionSet {
    let rawValue: Int

    static let x = AxisOptions(rawValue: 1 << 0)
    static let y = AxisOptions(rawValue: 1 << 1)
    static let z = AxisOptions(rawValue: 1 << 2)

    static let xy: AxisOptions = [.x, .y]
    static let all: AxisOptions = [.x, .y, .z]
}


extension AxisOptions {
    mutating func toggle(_ axis: AxisOptions) {
        if contains(axis) {
            remove(axis)
        } else {
            insert(axis)
        }
    }
}
