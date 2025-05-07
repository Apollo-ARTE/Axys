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
	var importedEntity: Entity?
	var anchorEntity: AnchorEntity?
	var webSocketTask: URLSessionWebSocketTask?
	var entityID: String?
	private var receivedUSDZData = Data()

	init(calibrationManager: CalibrationManager) {
		self.calibrationManager = calibrationManager
	}

	func disconnectFromWebSocket() {
		webSocketTask?.cancel()
		Logger.connection.info("Disconnected from WebSocket")
	}

    func connectToWebSocket() {
        guard let url = URL(string: "ws://\(Constants.ipAddress):3000") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        Logger.connection.info("Connected to WebSocket")
        receiveMessages()
    }

	private func receiveMessages() {
		webSocketTask?.receive { result in
			switch result {
			case .success(let message):
				switch message {
				case .string(let text):
					Logger.connection.info("Received message: \(text)")
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
	
func handleIncomingBinaryData(_ data: Data) {
	Logger.calibration.info("📦 Received binary data chunk. Size: \(data.count) bytes")
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
		if let message = try? decoder.decode(RhinoMessage.self, from: data) {
			Logger.calibration.info("📨 Received JSON message: \(text)")
			DispatchQueue.main.async {
				Logger.connection.info("Message position center: \(message.center.x), \(message.center.y), \(message.center.z)")
				let convertedPosition = SIMD3<Float>(
					Float(message.center.x),
					Float(message.center.y), // Rhino z becomes RealityKit y
					Float(message.center.z)  // Rhino y becomes RealityKit z
				)

                if let entity = self.importedEntity {
                    self.withMutation(keyPath: \.importedEntity) {
						let localPosition = self.calibrationManager.convertRobotToLocal(robot: convertedPosition)
                        entity.position = localPosition
						Logger.connection.info("Object moved to local coordinates: \(localPosition) (robot coordinates: \(convertedPosition)")
					}
				}
				if !message.objectId.isEmpty {
					self.entityID = message.objectId
					self.importedEntity?.name = message.objectId
				}
			}
		} else {
			if let metadata = try? decoder.decode(USDZMetadata.self, from: data), metadata.type == "usdz_metadata" {
				let fileManager = FileManager.default
				let tempDir = fileManager.temporaryDirectory
				let fileURL = tempDir.appendingPathComponent("received.usdz")
				
				if fileManager.fileExists(atPath: fileURL.path) {
					try? fileManager.removeItem(at: fileURL)
				}
				
				// Log received data size and expected metadata size
				Logger.calibration.info("🧮 Total USDZ bytes received: \(self.receivedUSDZData.count)")
				Logger.calibration.info("📏 Expected size from metadata: \(metadata.size) bytes")
				
				if self.receivedUSDZData.count != metadata.size {
					Logger.calibration.warning("⚠️ Mismatch between received and expected size. Waiting for more data?")
					return
				}
				
				do {
					let fileManager = FileManager.default
					let tempDir = fileManager.temporaryDirectory
					let fileURL = tempDir.appendingPathComponent("received.usdz")
					
					if fileManager.fileExists(atPath: fileURL.path) {
						try? fileManager.removeItem(at: fileURL)
					}
					
				try self.receivedUSDZData.write(to: fileURL)
				Logger.calibration.info("📂 File written successfully at \(fileURL.path)")
				Logger.calibration.info("✅ USDZ file saved to: \(fileURL.path)")
				
				let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
				let diskSize = fileAttributes?[.size] as? Int ?? -1
				Logger.calibration.info("📦 Disk-reported file size: \(diskSize) bytes")
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					do {
						Logger.calibration.info("✅ Attempting to load USDZ file at: \(fileURL.path)")
						let entity = try Entity.load(contentsOf: fileURL)
						entity.generateCollisionShapes(recursive: true)
						entity.components.set(InputTargetComponent())
						
						if let previousEntity = self.importedEntity {
							previousEntity.removeFromParent()
						}
						
						self.importedEntity = entity
						Logger.calibration.info("✅ USDZ entity loaded and stored in RhinoConnectionManager.")
					} catch {
						Logger.calibration.error("❌ Failed to load USDZ: \(error.localizedDescription)")
					}
				}
				} catch {
					Logger.calibration.error("❌ Failed to save/load USDZ file: \(error.localizedDescription)")
				}
				
				// Clear the buffer for the next file
				self.receivedUSDZData = Data()
				return
			} else {
				Logger.calibration.error("Failed to decode JSON: \(text)")
			}
		}
	}

	func sendPositionUpdate(for model: Entity, newPosition: SIMD3<Float>) {
		guard let webSocketTask = webSocketTask else { return }

		// Use the stored object ID or the sphere's name.
        let objectIDToSend = entityID ?? model.name
		if objectIDToSend.isEmpty {
			Logger.calibration.error("No valid object ID available; update will not be sent.")
			return
		}

        let pos = model.position
		let convertedCenter = Position(
			x: Double(pos.x / 1000),
			y: Double(pos.z / 1000), // RealityKit z becomes Rhino y
			z: Double(pos.y / 1000)  // RealityKit y becomes Rhino z
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
					Logger.calibration.error("Failed to send update: \(error)")
				} else {
					Logger.calibration.info("Update sent: \(jsonString)")
				}
			}
		}
	}
}
