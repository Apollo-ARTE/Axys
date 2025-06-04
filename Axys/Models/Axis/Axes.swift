//
//  AxesOptions.swift
//  Axys
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
