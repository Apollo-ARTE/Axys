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
	let session = ARKitSession()

	var firstMarkerEntity = Entity()
	var secondMarkerEntity = Entity()
	var thirdMarkerEntity = Entity()

	private var imageAnchors: [UUID: ImageAnchor] = [:]
	private var entityMap: [UUID: Entity] = [:]

	private let imageInfo = ImageTrackingProvider(
		referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "images")
	)

	init() {
		// Initialize each entity (customize these as needed)
		firstMarkerEntity = ModelEntity.movableSphere(color: .red)
		secondMarkerEntity = ModelEntity.movableSphere(color: .green)
		thirdMarkerEntity = ModelEntity.movableSphere(color: .blue)
	}

	func startTracking() {
		guard ImageTrackingProvider.isSupported else { return }

		Task {
			try await session.run([imageInfo])

			for await update in imageInfo.anchorUpdates {
				switch update.event {
				case .added, .updated:
					updateImage(update.anchor)
				case .removed:
					removeImage(update.anchor)
				}
			}
		}
	}

	private func updateImage(_ anchor: ImageAnchor) {
		guard anchor.isTracked,
				let imageName = anchor.referenceImage.name else { return }

		// Assign entity based on the reference image name
		if entityMap[anchor.id] == nil {
			switch imageName {
			case "marker1":
				entityMap[anchor.id] = firstMarkerEntity
			case "marker2":
				entityMap[anchor.id] = secondMarkerEntity
			case "marker3":
				entityMap[anchor.id] = thirdMarkerEntity
			default:
				break // Ignore unrecognized markers
			}
			imageAnchors[anchor.id] = anchor
		}

		// Update the corresponding entity's transform
		entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
	}

	private func removeImage(_ anchor: ImageAnchor) {
		entityMap.removeValue(forKey: anchor.id)
		imageAnchors.removeValue(forKey: anchor.id)
	}
}
