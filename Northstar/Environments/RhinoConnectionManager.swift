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
    var anchorEntity: AnchorEntity?
    var webSocketTask: URLSessionWebSocketTask?
    var entityID: String?

	var ipAddress: String = .load(key: "rhino_ip") ?? "" {
		didSet {
			ipAddress.save(key: "rhino_ip")
		}
	}

	var isConnected: Bool = false

    var trackedObjects: [RhinoObject]? // An array to store the tracked objects upon receival
    var createMessageReceived: Bool = false

    var rhinoRootEntity: Entity

	private var receivedUSDZData = Data()

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
        Logger.connection.info("Connected to WebSocket")
        receiveMessages()
        trackedObjects = []
		isConnected = true
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
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
//                    Logger.connection.info("Received message: \(text)")
                    self.handleIncomingJSON(text)
                case .data(let data):
                    self.handleIncomingBinaryData(data)
                    //				default:
                    //					Logger.calibration.info("Unsupported message type")
                @unknown default:
                    fatalError()
                }
            case .failure(let error):
                Logger.connection.error("WebSocket error: \(error.localizedDescription)")
            }
            // Continue listening for messages.
            self.receiveMessages()
        }
    }

    @MainActor
	func addObjectsToView() async {
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
        } else if let message = try? decoder.decode(InfoMessage.self, from: data) {
            if message.type == "error" {
                Logger.connection.error("Rhino error: \(message.description) at \(message.timestamp)")
            } else if message.type == "info" {
                Logger.connection.info("Rhino info: \(message.description) at \(message.timestamp)")
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
                    Logger.connection.debug("Disk-reported file size: \(diskSize) bytes")
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
