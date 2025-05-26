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
	static let connection = Logger(subsystem: subsystem, category: "Connection")
    static let rhino = Logger(subsystem: subsystem, category: "Rhino")
    static let views = Logger(subsystem: subsystem, category: "Views")
}
