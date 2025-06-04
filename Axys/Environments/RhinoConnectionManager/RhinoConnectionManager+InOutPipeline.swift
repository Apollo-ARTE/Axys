//  RhinoConnectionManager+InOutPipeline.swift
//  Axys
//
//  Created by Salvatore Flauto on 01/04/25.
//

import Foundation
import RealityKit
import OSLog

extension RhinoConnectionManager {
	/// Sends a command string to the Rhino WebSocket server.
	///
	/// This method constructs a JSON message in the format `{"command": "<value>"}`
	/// and sends it over the active WebSocket connection. It logs success or failure
	/// and sets `isImportingObjects` to `true` if the message was sent successfully.
	///
	/// - Parameter value: A `String` representing the command to send (e.g., `"TrackObject"`).
	///
	/// - Note: If the WebSocket connection is not initialized, the method logs an error and returns early.
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
