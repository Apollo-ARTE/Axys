//
//  ImageTrackingManager.swift
//  Image Calibration
//
//  Created by Alessandro Bortoluzzi on 05/03/25.
//

import ARKit
import RealityKit

@MainActor
@Observable
class ImageTrackingManager {
	init(calibrationManager: CalibrationManager) {
		self.calibrationManager = calibrationManager
	}

	var calibrationManager: CalibrationManager

	let session = ARKitSession()

	var rootEntity = Entity()
	var firstMarkerEntity: Entity?
	var secondMarkerEntity: Entity?
	var thirdMarkerEntity: Entity?

	private(set) var scannedMarkers: Set<String> = []
	private var imageAnchors: [UUID: ImageAnchor] = [:]
	private var entityMap: [UUID: Entity] = [:]

	private let imageInfo = ImageTrackingProvider(
		referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "images")
	)

	func startTracking() {
		guard ImageTrackingProvider.isSupported else { return }

		Task {
			try await session.run([imageInfo])

			for await update in imageInfo.anchorUpdates {
				switch update.event {
				case .added:
					updateImage(update.anchor)
				case .updated:
					updateImage(update.anchor)
				case .removed:
					removeImage(update.anchor)
				}
			}
		}
	}

	func isMarkerScanned(_ markerName: String) -> Bool {
		scannedMarkers.contains(markerName)
	}

	private func updateImage(_ anchor: ImageAnchor) {
		guard
			anchor.isTracked,
			let imageName = anchor.referenceImage.name,
			let markerNumber = Self.markerNumber(from: imageName)
		else { return }

		// Only consume anchors that correspond to the *current* scan step.
		guard
			case .scanMarker(let expectedNumber) = calibrationManager.calibrationStep,
			expectedNumber == markerNumber else {
			return // Either we are past this step or it is not yet this marker's turn.
		}

		if entityMap[anchor.id] == nil {
			let entity = ModelEntity.markerSphere()
			entityMap[anchor.id] = entity
			imageAnchors[anchor.id] = anchor
			rootEntity.addChild(entity)

			switch markerNumber {
			case 1: firstMarkerEntity = entity
			case 2: secondMarkerEntity = entity
			case 3: thirdMarkerEntity = entity
			default: break
			}

			scannedMarkers.insert(imageName)
		}

		entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
	}

	private func removeImage(_ anchor: ImageAnchor) {
		entityMap.removeValue(forKey: anchor.id)
		imageAnchors.removeValue(forKey: anchor.id)
	}

	private static func markerNumber(from imageName: String) -> Int? {
		guard imageName.hasPrefix("marker") else { return nil }
		return Int(imageName.dropFirst("marker".count))
	}
}
