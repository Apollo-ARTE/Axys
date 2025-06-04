//
//  RhinoConnectionManager+ManageMessage.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

import Foundation
import OSLog

extension RhinoConnectionManager {
	/// Handles a `batch_create` message by constructing and storing `RhinoObject` instances.
	///
	/// Each object is decoded from the message and mapped by its unique `objectId`.
	///
	/// - Parameter message: A decoded `BatchRhinoMessage` containing multiple Rhino objects.
	internal func handleBatchCreateMessage(_ message: BatchRhinoMessage) {
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

			self.receivedObjects[object.objectId] = rhinoObject
			self.isImportingObjects = false

			Logger.connection.info("Object named \(object.objectName) with position: \(rhinoPosition) added/updated")
		}
	}

	/// Processes informational or error messages received from Rhino.
	///
	/// Updates state flags and logs messages to assist with UI alerts and debugging.
	///
	/// - Parameter message: A decoded `InfoMessage` containing status or error details.
	internal func handleInfoOrErrorMessage(_ message: InfoMessage) {
		switch message.type {
		case "error":
			Logger.rhino.error("Rhino error: \(message.description) at \(message.timestamp)")
			self.isImportingObjects = false
			self.errorAlertShown = true
			self.rhinoErrorMessage = message.description

		case "info":
			Logger.rhino.info("Rhino info: \(message.description) at \(message.timestamp)")

		default:
			break
		}
	}

	/// Processes metadata for an incoming USDZ file and saves the file to disk once complete.
	///
	/// Validates the received binary size against the expected size in metadata before writing to a temporary file.
	///
	/// - Parameter metadata: A decoded `USDZMetadata` object containing file info such as name and size.
	internal func handleUSDZMetadata(_ metadata: USDZMetadata) {
		let fileManager = FileManager.default
		let tempDir = fileManager.temporaryDirectory
		let fileURL = tempDir.appendingPathComponent(metadata.fileName)

		// Remove any existing file with the same name
		if fileManager.fileExists(atPath: fileURL.path) {
			try? fileManager.removeItem(at: fileURL)
		}

		// Log data size expectations
		Logger.connection.debug("Total USDZ bytes received: \(self.receivedUSDZData.count)")
		Logger.connection.debug("Expected size from metadata: \(metadata.size) bytes")

		guard self.receivedUSDZData.count == metadata.size else {
			Logger.connection.warning("Mismatch between received and expected size, waiting for more data")
			return
		}

		do {
			try self.receivedUSDZData.write(to: fileURL)
			Logger.connection.info("Model file written successfully at \(fileURL.path)")

			let fileAttributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
			let diskSize = fileAttributes?[.size] as? Int ?? -1
			Logger.connection.debug("Written USDZ file size: \(diskSize) bytes")

			self.sendCommand(value: "TrackObject")
		} catch {
			Logger.connection.error("Failed to save/load USDZ file: \(error.localizedDescription)")
		}

		self.receivedUSDZData = Data()
	}
}
