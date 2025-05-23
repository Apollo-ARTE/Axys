//  RhinoConnectionManager+InOutPipeline.swift
//  Northstar
//
//  Created by Salvatore Flauto on 01/04/25.
//

import Foundation
import RealityKit
import OSLog

extension RhinoConnectionManager {
    func sendCommand(value: String) {
		guard let webSocketTask = webSocketTask else {
            Logger.connection.error("WebSocket not initialized.")
			return
		}
		let command = ["command": value]
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: command)
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				let message = URLSessionWebSocketTask.Message.string(jsonString)
				webSocketTask.send(message) { error in
					if let error = error {
						Logger.connection.error("Error sending message: \(error.localizedDescription)")
					} else {
                        Logger.connection.debug("Command sent: \(value)")
						self.isImportingObjects = true
					}
				}
			}
		} catch {
            Logger.connection.error("Error serializing JSON: \(error.localizedDescription)")
		}
	}
}
