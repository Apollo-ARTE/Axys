//
//  Logger+Ext.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import OSLog

extension Logger {
	private static let subsystem = Bundle.main.bundleIdentifier ?? "Axys"

	static let calibration = Logger(subsystem: subsystem, category: "Calibration")
	static let connection = Logger(subsystem: subsystem, category: "Connection")
    static let rhino = Logger(subsystem: subsystem, category: "Rhino")
	static let models = Logger(subsystem: subsystem, category: "Models")
    static let views = Logger(subsystem: subsystem, category: "Views")
}
