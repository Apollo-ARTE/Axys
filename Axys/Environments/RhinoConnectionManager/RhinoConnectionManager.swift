//
//  RhinoConnectionManager.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 25/03/25.
//

import Foundation
import RealityKit
import OSLog
import SwiftUI

/// Manages the WebSocket connection and object synchronization between Vision Pro and Rhino.
///
/// Handles connection setup, message parsing, calibration-based coordinate conversion, and rendering Rhino objects in the AR scene.
@Observable
class RhinoConnectionManager {
    let calibrationManager: CalibrationManager
    var anchorEntity: AnchorEntity?
    var webSocketTask: URLSessionWebSocketTask?
    var entityID: String?

	var ipAddress: String = .load(key: "rhino_ip") ?? "" {
		didSet {
			ipAddress.save(key: "rhino_ip")
		}
	}

	var isConnected: Bool = false

    var createMessageReceived: Bool = false
	var isImportingObjects: Bool = false
    var errorAlertShown: Bool = false
    var rhinoErrorMessage: String?

    var rhinoRootEntity: Entity

	var receivedUSDZData = Data()

	private let processingQueue = DispatchQueue(label: "com.app.websocket.processing", qos: .userInitiated)

    var receivedObjects: [String: RhinoObject] = [:]
    // Computed property to get array of objects when needed to display
    var trackedObjects: [RhinoObject] {
        return Array(receivedObjects.values)
    }

    init(calibrationManager: CalibrationManager) {
        self.calibrationManager = calibrationManager
        self.rhinoRootEntity = Entity()
        self.rhinoRootEntity.name = "rhino_root"
    }

	/// Disconnects the WebSocket connection to the Rhino server and updates connection state.
    func disconnectFromWebSocket() {
        webSocketTask?.cancel()
        Logger.connection.info("Disconnected from WebSocket")
		isConnected = false
    }

	/// Establishes a WebSocket connection to the Rhino server using the current IP address.
    func connectToWebSocket() {
        guard let url = URL(string: "ws://\(ipAddress):8765") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessages()
        receivedObjects = [:]
    }

	/// Validates the format of the current IP address string.
	/// - Returns: `true` if the IP address is valid, `false` otherwise.
	func isValidIPAddress() -> Bool {
		let pattern = #"^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$"#
		let regex = try! NSRegularExpression(pattern: pattern)
		let range = NSRange(location: 0, length: ipAddress.utf16.count)
		return regex.firstMatch(in: ipAddress, options: [], range: range) != nil
	}

	/// Sends a position update message to Rhino for a specific object.
	/// - Parameters:
	///   - model: The entity whose position was updated.
	///   - newPosition: The new position of the object in robot coordinates.
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

	/// Continuously listens for incoming messages on the WebSocket and dispatches them for processing.
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
				isConnected = true
				Logger.connection.info("Connected to WebSocket")
                switch message {
                case .string(let text):
                    self.processingQueue.async {
                        self.handleIncomingJSON(text)
                    }
                case .data(let data):
                    self.processingQueue.async {
                        self.handleIncomingBinaryData(data)
                    }
                @unknown default:
					Logger.connection.error("Unknown message received")
                }
            case .failure(let error):
                Logger.connection.error("WebSocket error: \(error.localizedDescription)")
            }

            // Continue listening for messages
            self.receiveMessages()
        }
    }

	/// Adds all currently tracked Rhino objects to the AR scene using local coordinates.
	/// Requires a completed calibration.
	/// - Note: This method removes previously added objects.
    @MainActor
	func addObjectsToView() async {
		guard calibrationManager.isCalibrationCompleted else {
			Logger.models.info("Calibration not completed yet. Skipping adding objects to view.")
			return
		}

        self.rhinoRootEntity.children.removeAll()
        Logger.models.info("Removing all children from rhino root entity")

		for object in trackedObjects {
			// Attempt to asynchronously load the ModelEntity for the object using its unique ID
			if let rhinoObject = try? await ModelEntity.rhinoObject(name: object.objectId) {
				// Set identifying components for debugging or tracking
				rhinoObject.components.set(NameComponent(objectName: object.objectName))
				rhinoObject.components.set(AxesComponent()) // Adds XYZ axes for orientation visualization
				rhinoObject.name = object.objectId // Assign the object ID as the entity's name for easy reference

				// Convert the object's position from robot space to local (Vision Pro) coordinates
				let localPosition = self.calibrationManager.convertRobotToLocal(robot: object.rhinoPosition)

				// Orient the object to look in a fixed direction (toward world Y+ in robot space)
				rhinoObject.look(
					at: calibrationManager.convertRobotToLocal(robot: [0, 10, 0]),
					from: calibrationManager.convertRobotToLocal(robot: [0, 0, 0]),
					relativeTo: nil
				)

				// Set the object's position in the AR scene
				rhinoObject.position = localPosition

				// If the object is named "Table", apply a gray non-metallic material
				if rhinoObject.components[NameComponent.self]?.objectName == "Table" {
					let material = SimpleMaterial(color: .gray, isMetallic: false)
					rhinoObject.model?.materials = [material]
				}

				// Add the object to the root entity for the Rhino AR scene
				self.rhinoRootEntity.addChild(rhinoObject)

				Logger.connection.info("Placing object: \(object.objectName)")
				Logger.connection.info("Object Local position: \(localPosition)")
				Logger.connection.info("Object Robot coordinates: \(object.rhinoPosition)")
			}
		}
    }

	/// Appends binary data received from the WebSocket. Currently used for assembling USDZ files.
	/// - Parameter data: The binary data chunk received.
    func handleIncomingBinaryData(_ data: Data) {
        self.receivedUSDZData.append(data)
        func applyDebugMaterial(to entity: Entity) {
            if let modelEntity = entity as? ModelEntity {
                modelEntity.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
            }
            for child in entity.children {
                applyDebugMaterial(to: child)
            }
        }
    }

	/// Parses and routes incoming JSON messages received from the WebSocket.
	///
	/// This method attempts to decode the JSON string into one of the known message types (`BatchRhinoMessage`, `InfoMessage`, or `USDZMetadata`)
	/// and delegates further handling to the appropriate internal method.
	///
	/// - Parameter text: A JSON-encoded string received from the WebSocket connection.
	func handleIncomingJSON(_ text: String) {
		guard let data = text.data(using: .utf8) else { return }
		let decoder = JSONDecoder()

		// Attempt to decode and dispatch to the correct handler
		if let batchMessage = try? decoder.decode(BatchRhinoMessage.self, from: data), batchMessage.type == "batch_create" {
			handleBatchCreateMessage(batchMessage)
		} else if let infoMessage = try? decoder.decode(InfoMessage.self, from: data) {
			handleInfoOrErrorMessage(infoMessage)
		} else if let metadata = try? decoder.decode(USDZMetadata.self, from: data), metadata.type == "usdz_metadata" {
			handleUSDZMetadata(metadata)
		} else {
			Logger.connection.error("Failed to decode JSON: \(text)")
		}
	}
}
