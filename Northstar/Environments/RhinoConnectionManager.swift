//
//  RhinoConnectionManager.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation
import RealityKit
import OSLog

@Observable
class RhinoConnectionManager {
	let calibrationManager: CalibrationManager
	var object: Entity?
	var webSocketTask: URLSessionWebSocketTask?
	var entityID: String?

	init(calibrationManager: CalibrationManager) {
		self.calibrationManager = calibrationManager
	}

	func disconnectFromWebSocket() {
		webSocketTask?.cancel()
		Logger.connection.info("Disconnected from WebSocket")
	}

	func connectToWebSocket() {
		guard let url = URL(string: "ws://\(Constants.ipAddress):8765") else { return }
		webSocketTask = URLSession.shared.webSocketTask(with: url)
		webSocketTask?.resume()
		Logger.connection.info("Connected to WebSocket")
		receiveMessages()
	}

	func sendPositionUpdate(for sphere: Entity, newPosition: SIMD3<Float>) {
		guard let webSocketTask = webSocketTask else { return }

		// Use the stored object ID or the sphere's name.
		let objectIDToSend = entityID ?? sphere.name
		if objectIDToSend.isEmpty {
			Logger.connection.error("No valid object ID available; update will not be sent.")
			return
		}

		let pos = newPosition
		let convertedCenter = Position(
			x: Double(pos.x),
			y: Double(pos.y),
			z: Double(pos.z)
		)

		let updateMessage = RhinoMessage(
			type: "update",
			objectId: objectIDToSend,
			center: convertedCenter,
			radius: 0.0,  // Not needed for an update
			timestamp: Date().timeIntervalSince1970 * 1000
		)

		let encoder = JSONEncoder()
		if let data = try? encoder.encode(updateMessage), let jsonString = String(data: data, encoding: .utf8) {
			let message = URLSessionWebSocketTask.Message.string(jsonString)
			webSocketTask.send(message) { error in
				if let error = error {
					Logger.connection.error("Failed to send update: \(error)")
				} else {
					Logger.connection.info("Update sent: \(jsonString)")
				}
			}
		}
	}

	private func receiveMessages() {
		webSocketTask?.receive { result in
			switch result {
			case .success(let message):
				switch message {
				case .string(let text):
					Logger.connection.info("Received message: \(text)")
					self.handleIncomingJSON(text)
				default:
					Logger.connection.info("Unsupported message type")
				}
			case .failure(let error):
				Logger.connection.error("WebSocket error: \(error)")
			}
			// Continue listening for messages.
			self.receiveMessages()
		}
	}

	private func handleIncomingJSON(_ text: String) {
		guard let data = text.data(using: .utf8) else { return }
		let decoder = JSONDecoder()
		if let message = try? decoder.decode(RhinoMessage.self, from: data) {
			DispatchQueue.main.async {
				Logger.connection.info("Message position center: \(message.center.x), \(message.center.y), \(message.center.z)")
				let convertedPosition = SIMD3<Float>(
					Float(message.center.x),
					Float(message.center.y), // Rhino z becomes RealityKit y
					Float(message.center.z)  // Rhino y becomes RealityKit z
				)
				if let sphere = self.object {
					self.withMutation(keyPath: \.object) {
						let localPosition = self.calibrationManager.convertRobotToLocal(robot: convertedPosition)
						sphere.position = localPosition
						Logger.connection.info("Object moved to local coordinates: \(localPosition) (robot coordinates: \(convertedPosition)")
					}
				}
				if !message.objectId.isEmpty {
					self.entityID = message.objectId
					self.object?.name = message.objectId
				}
			}
		} else {
			Logger.calibration.error("Failed to decode JSON: \(text)")
		}
	}
}
