//
//  Logger+Ext.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import OSLog

extension Logger {
	private static let subsystem = Bundle.main.bundleIdentifier ?? "Northstar"

	static let calibration = Logger(subsystem: subsystem, category: "Calibration")
}
