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

    var receivedObjects: [String: RhinoObject]?
    var createMessageReceived: Bool = false

    var rhinoRootEntity = Entity()

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
        receivedObjects = [:]
	}

	func sendPositionUpdate(for model: Entity, newPosition: SIMD3<Float>) {
		guard let webSocketTask = webSocketTask else { return }

		// Use the stored object ID or the sphere's name.
		let objectIDToSend = entityID ?? model.name
		if objectIDToSend.isEmpty {
			Logger.connection.error("No valid object ID available; update will not be sent.")
			return
		}
        let objectName = model.name

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

    @MainActor
    private func addObjectsToView() async {
        self.rhinoRootEntity.children.removeAll()
        Logger.connection.info("Removing all children from rhino root entity")

        for (_, object) in receivedObjects ?? [:] {
            if let rhinoObject = try? await ModelEntity.rhinoObject(name: object.objectName) {
                self.rhinoRootEntity.addChild(rhinoObject)
                rhinoObject.name = object.objectName
                let localPosition = self.calibrationManager.convertRobotToLocal(robot: object.convertedPosition)
                withMutation(keyPath: \.rhinoRootEntity) {
                    rhinoObject.position = localPosition
                }
                Logger.connection.info("Object named \(object.objectName) moved to local coordinates: \(localPosition) (robot coordinates: \(object.convertedPosition)")
                }
        }
    }

//    private func removeObjectsFromView() {
//        withMutation(keyPath: \.rhinoRootEntity) {
//            self.rhinoRootEntity.children.removeAll()
//            Logger.connection.info("Removing all children from rhino root entity")
//        }
//    }

	private func handleIncomingJSON(_ text: String) {
		guard let data = text.data(using: .utf8) else { return }
		let decoder = JSONDecoder()
        if let message = try? decoder.decode(RhinoMessage.self, from: data) {
            if message.type == "create" {
//                self.removeObjectsFromView()
                Logger.connection.info("Message position center: \(message.center.x), \(message.center.y), \(message.center.z)")
                let convertedPosition = SIMD3<Float>(
                    Float(message.center.x),
                    Float(message.center.y), // Rhino z becomes RealityKit y
                    Float(message.center.z)  // Rhino y becomes RealityKit z
                )
                self.receivedObjects?[message.objectId] = RhinoObject(
                    objectName: message.objectName,
                    convertedPosition: convertedPosition
                )
            }
        } else if let message = try? decoder.decode(BatchRhinoMessage.self, from: data) {
            if message.type == "batch_create" {
//                self.removeObjectsFromView()
                for object in message.objects {
                    Logger.connection.info("Message position center: \(object.center.x), \(object.center.y), \(object.center.z)")
                    let convertedPosition = SIMD3<Float>(
                        Float(object.center.x),
                        Float(object.center.y),
                        Float(object.center.z)
                    )
                    self.receivedObjects?[object.objectId] = RhinoObject(
                        objectName: object.objectName,
                        convertedPosition: convertedPosition
                    )
                    Logger.connection.info("Object named \(object.objectName) with position: \(convertedPosition) added to array")
                }
            }

			DispatchQueue.main.async {
                Task {
                    await self.addObjectsToView()
                }
////                        Task {
////                            if let rhinoObject = try? await ModelEntity.rhinoObject(name: objectName) {
////                                rhinoObject.name = objectName
////                                self.rhinoRootEntity.addChild(rhinoObject)
////                            }
//                            if let object = self.rhinoRootEntity.findEntity(named: objectName) {
//                                self.withMutation(keyPath: \.object) {
//                                    let localPosition = self.calibrationManager.convertRobotToLocal(robot: convertedPosition)
//                                    object.position = localPosition
//                                    Logger.connection.info("Object named \(objectName) moved to local coordinates: \(localPosition) (robot coordinates: \(convertedPosition)")
//                                }
//                            }
//                            if !message.objectId.isEmpty {
//                                self.entityID = message.objectId
//                                self.object?.name = message.objectId
//                            }
//                        }
////                    self.objectNameDict?[message.objectId] = message.objectName // add object name and ID to array
////                    Logger.connection.info("New object added to array: \(self.objectNameDict ?? [:])")
////                    self.createMessageReceived = true
//                }
			}
		} else {
			Logger.calibration.error("Failed to decode JSON: \(text)")
		}
	}
}
