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
    private let processingQueue = DispatchQueue(label: "com.app.websocket.processing", qos: .userInitiated)

    var createMessageReceived: Bool = false
	var isImportingObjects: Bool = false
    var errorAlertShown: Bool = false
    var rhinoErrorMessage: String?

    var rhinoRootEntity: Entity

	private var receivedUSDZData = Data()

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

    func disconnectFromWebSocket() {
        webSocketTask?.cancel()
        Logger.connection.info("Disconnected from WebSocket")
		isConnected = false
    }

    func connectToWebSocket() {
        guard let url = URL(string: "ws://\(ipAddress):8765") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessages()
        receivedObjects = [:]
    }

	func isValidIPAddress() -> Bool {
		let pattern = #"^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$"#
		let regex = try! NSRegularExpression(pattern: pattern)
		let range = NSRange(location: 0, length: ipAddress.utf16.count)
		return regex.firstMatch(in: ipAddress, options: [], range: range) != nil
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
                    fatalError()
                }
            case .failure(let error):
                Logger.connection.error("WebSocket error: \(error.localizedDescription)")
            }

            // Continue listening for messages
            self.receiveMessages()
        }
    }

    @MainActor
	func addObjectsToView() async {
		guard calibrationManager.isCalibrationCompleted else {
			Logger.connection.info("Calibration not completed yet. Skipping adding objects to view.")
			return
		}

        self.rhinoRootEntity.children.removeAll()
        Logger.connection.info("Removing all children from rhino root entity")
        for object in trackedObjects {
            if let rhinoObject = try? await ModelEntity.rhinoObject(name: object.objectId) {
				rhinoObject.components.set(NameComponent(objectName: object.objectName))
				rhinoObject.components.set(AxesComponent())
                rhinoObject.name = object.objectId // Setting the Rhino ID as name of the object for easy identification
                let localPosition = self.calibrationManager.convertRobotToLocal(robot: object.rhinoPosition)
                rhinoObject.look(
                    at: calibrationManager.convertRobotToLocal(robot: [0, 10, 0]),
                    from: calibrationManager.convertRobotToLocal(robot: [0, 0, 0]),
                    relativeTo: nil)
                rhinoObject.position = localPosition
                if rhinoObject.components[NameComponent.self]?.objectName == "Table" {
                    var material = SimpleMaterial(color: .gray, isMetallic: false)
                    rhinoObject.model?.materials = [material]
                }
//                rhinoObject.transform.scale = [0, 0, 0]
                self.rhinoRootEntity.addChild(rhinoObject)
                Logger.connection.info("Object named \(object.objectName) moved to local coordinates: \(localPosition) robot coordinates: \(object.rhinoPosition), object scale: \(rhinoObject.transform.scale)")
            }
        }
    }

    func handleIncomingBinaryData(_ data: Data) {
//        Logger.connection.debug("Received binary data chunk. Size: \(data.count) bytes")
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

    struct USDZMetadata: Decodable {
        let type: String
        let fileName: String
        let size: Int
        let timestamp: Int
    }

    func handleIncomingJSON(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        if let message = try? decoder.decode(BatchRhinoMessage.self, from: data) {
            if message.type == "batch_create" {
                for object in message.objects {
                    Logger.connection.debug("Message position center: \(object.center.x), \(object.center.y), \(object.center.z)")
                    let rhinoPosition = SIMD3<Float>(
                        Float(object.center.x),
                        Float(object.center.y),
                        Float(object.center.z)
                    )

                    let rhinoObject = RhinoObject(
                        objectId: object.objectId,
                        objectName: object.objectName,
                        rhinoPosition: rhinoPosition
                    )

                    // Add or update object using objectId as key
                    self.receivedObjects[object.objectId] = rhinoObject
					isImportingObjects = false

                    Logger.connection.info("Object named \(object.objectName) with position: \(rhinoPosition) added/updated")
                }
            }
        } else if let message = try? decoder.decode(InfoMessage.self, from: data) {
            if message.type == "error" {
                Logger.rhino.error("Rhino error: \(message.description) at \(message.timestamp)")
                isImportingObjects = false
                errorAlertShown = true
                rhinoErrorMessage = message.description
            } else if message.type == "info" {
                Logger.rhino.info("Rhino info: \(message.description) at \(message.timestamp)")
            }
        } else {
            if let metadata = try? decoder.decode(USDZMetadata.self, from: data), metadata.type == "usdz_metadata" {
                let fileManager = FileManager.default
                let tempDir = fileManager.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("\(metadata.fileName)")

                if fileManager.fileExists(atPath: fileURL.path) {
                    try? fileManager.removeItem(at: fileURL)
                }

                // Log received data size and expected metadata size
                Logger.connection.debug("Total USDZ bytes received: \(self.receivedUSDZData.count)")
                Logger.connection.debug("Expected size from metadata: \(metadata.size) bytes")

                if self.receivedUSDZData.count != metadata.size {
                    Logger.connection.warning("Mismatch between received and expected size. Waiting for more data?")
                    return
                }

                do {
                    let fileManager = FileManager.default
                    let tempDir = fileManager.temporaryDirectory
                    let fileURL = tempDir.appendingPathComponent("\(metadata.fileName)")

                    if fileManager.fileExists(atPath: fileURL.path) {
                        try? fileManager.removeItem(at: fileURL)
                    }
                    try self.receivedUSDZData.write(to: fileURL)
                    Logger.connection.info("Model file written successfully at \(fileURL.path)")

                    let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                    let diskSize = fileAttributes?[.size] as? Int ?? -1
//                    Logger.connection.info("Disk-reported file size: \(diskSize) bytes")
                    // Send the command to get object tracking information
                    self.sendCommand(value: "TrackObject")
                } catch {
                    Logger.connection.error("Failed to save/load USDZ file: \(error.localizedDescription)")
                }

                // Clear the buffer for the next file
                self.receivedUSDZData = Data()
                return
            } else {
                Logger.connection.error("Failed to decode JSON: \(text)")
            }
        }
    }
}
