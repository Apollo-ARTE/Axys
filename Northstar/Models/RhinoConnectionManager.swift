//
//  RhinoConnectionManager.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation
import RealityKit

@Observable
class RhinoConnectionManager {
	var sphereEntity: Entity?
	var webSocketTask: URLSessionWebSocketTask?
	var entityID: String?

	func connectToWebSocket() {
		guard let url = URL(string: "ws://10.20.58.109:8765") else { return }
		webSocketTask = URLSession.shared.webSocketTask(with: url)
		webSocketTask?.resume()
		receiveMessages()
	}

	func receiveMessages() {
		webSocketTask?.receive { result in
			switch result {
			case .success(let message):
				switch message {
				case .string(let text):
					self.handleIncomingJSON(text)
				default:
					print("Unsupported message type")
				}
			case .failure(let error):
				print("WebSocket error: \(error)")
			}
			// Continue listening for messages.
			self.receiveMessages()
		}
	}

	func handleIncomingJSON(_ text: String) {
		guard let data = text.data(using: .utf8) else { return }
		let decoder = JSONDecoder()
		if let message = try? decoder.decode(RhinoMessage.self, from: data) {
			DispatchQueue.main.async {
				let convertedPosition = SIMD3<Float>(
					Float(message.center.x),
					Float(message.center.z), // Rhino z becomes RealityKit y
					Float(message.center.y)  // Rhino y becomes RealityKit z
				)
				if let sphere = self.sphereEntity {
					sphere.position = convertedPosition
				}
				if !message.objectId.isEmpty {
					self.entityID = message.objectId
					self.sphereEntity?.name = message.objectId
				}
			}
		} else {
			print("Failed to decode JSON: \(text)")
		}
	}

	func sendPositionUpdate(for sphere: Entity) {
		guard let webSocketTask = webSocketTask else { return }

		// Use the stored object ID or the sphere's name.
		let objectIDToSend = entityID ?? sphere.name
		if objectIDToSend.isEmpty {
			print("No valid object ID available; update will not be sent.")
			return
		}

		let pos = sphere.position
		let convertedCenter = Position(
			x: Double(pos.x),
			y: Double(pos.z), // RealityKit z becomes Rhino y
			z: Double(pos.y)  // RealityKit y becomes Rhino z
		)

		let updateMessage = RhinoMessage(
			type: "update",
			objectId: objectIDToSend,
			center: convertedCenter,
			radius: 0.0,  // Not needed for an update
			timestamp: Date().timeIntervalSince1970 * 1000
		)

		let encoder = JSONEncoder()
		if let data = try? encoder.encode(updateMessage),
		   let jsonString = String(data: data, encoding: .utf8) {
			let message = URLSessionWebSocketTask.Message.string(jsonString)
			webSocketTask.send(message) { error in
				if let error = error {
					print("Failed to send update: \(error)")
				} else {
					print("Update sent: \(jsonString)")
				}
			}
		}
	}
}
