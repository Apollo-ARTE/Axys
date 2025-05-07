//
//  RhinoConnectionManager.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation
import RealityKit
import OSLog
import SwiftUI

@Observable
class RhinoConnectionManager {
	let calibrationManager: CalibrationManager
	var object: Entity?
	var webSocketTask: URLSessionWebSocketTask?
	var entityID: String?

    var trackedObjects: [RhinoObject]? // An array to store the tracked objects upon receival
    var createMessageReceived: Bool = false

    var rhinoRootEntity: Entity

	init(calibrationManager: CalibrationManager) {
		self.calibrationManager = calibrationManager
        self.rhinoRootEntity = Entity()
        self.rhinoRootEntity.name = "rhino_root"
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
        trackedObjects = []
	}

	func sendPositionUpdate(for model: Entity, newPosition: SIMD3<Float>) {
		guard let webSocketTask = webSocketTask else { return }

		// Use the stored object ID or the sphere's name.
        let objectIDToSend = model.name
        let objectName = "Unspecified"

		let pos = newPosition
		let convertedCenter = Position(
			x: Double(pos.x),
			y: Double(pos.y),
			z: Double(pos.z)
		)

		let updateMessage = RhinoMessage(
			type: "update",
            objectName: objectName,
			objectId: objectIDToSend,
			center: convertedCenter,
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

    // TODO: Refactor to add objects on first open of the immersive view after calibration
    @MainActor
    private func addObjectsToView() async {
        self.rhinoRootEntity.children.removeAll()
        Logger.connection.info("Removing all children from rhino root entity")
        for object in trackedObjects ?? [] {
            if let rhinoObject = try? await ModelEntity.rhinoObject(name: object.objectId) {
                rhinoObject.name = object.objectId // Setting the Rhino ID as name of the object for easy identification
                let localPosition = self.calibrationManager.convertRobotToLocal(robot: object.rhinoPosition)
                rhinoObject.look(
                    at: calibrationManager.convertRobotToLocal(robot: [0, 10, 0]),
                    from: calibrationManager.convertRobotToLocal(robot: [0, 0, 0]),
                    relativeTo: nil)
                rhinoObject.position = localPosition
                rhinoObject.transform.scale = [0, 0, 0]
                self.rhinoRootEntity.addChild(rhinoObject)
                Logger.connection.info("Object named \(object.objectName) moved to local coordinates: \(localPosition) robot coordinates: \(object.rhinoPosition), object scale: \(rhinoObject.transform.scale)")
            }
        }
    }

	private func handleIncomingJSON(_ text: String) {
		guard let data = text.data(using: .utf8) else { return }
		let decoder = JSONDecoder()
        if let message = try? decoder.decode(RhinoMessage.self, from: data) {
            self.trackedObjects = []
            if message.type == "create" {
                Logger.connection.debug("Message position center: \(message.center.x), \(message.center.y), \(message.center.z)")
                let rhinoPosition = SIMD3<Float>(
                    Float(message.center.x),
                    Float(message.center.y),
                    Float(message.center.z)
                )
                self.trackedObjects?.append(RhinoObject(
                    objectId: message.objectId,
                    objectName: message.objectName,
                    rhinoPosition: rhinoPosition
                ))
            }
        } else if let message = try? decoder.decode(BatchRhinoMessage.self, from: data) {
            if message.type == "batch_create" {
                self.trackedObjects = []
                for object in message.objects {
                    Logger.connection.debug("Message position center: \(object.center.x), \(object.center.y), \(object.center.z)")
                    let rhinoPosition = SIMD3<Float>(
                        Float(object.center.x),
                        Float(object.center.y),
                        Float(object.center.z)
                    )
                    self.trackedObjects?.append(RhinoObject(
                        objectId: object.objectId,
                        objectName: object.objectName,
                        rhinoPosition: rhinoPosition
                    ))
                    Logger.connection.info("Object named \(object.objectName) with position: \(rhinoPosition) added to array")
                }
            }

            Task {
                await self.addObjectsToView()
            }
		} else {
			Logger.calibration.error("Failed to decode JSON: \(text)")
		}
	}
}
