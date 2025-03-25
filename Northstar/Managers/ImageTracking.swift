//
//  ImageTracking.swift
//  Image Calibration
//
//  Created by Alessandro Bortoluzzi on 05/03/25.
//

import ARKit
import RealityKit

@MainActor
@Observable
class ImageTracking {
	let session = ARKitSession()

	var planeAnchors: [UUID: ImageAnchor] = [:]
	var entityMap: [UUID: Entity] = [:]

	var centerEntity: Entity
	var movableEntity: ModelEntity

	var modelPosition: SIMD3<Float> = .zero

	let imageInfo = ImageTrackingProvider(
		referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "images")
	)

	init() {
		centerEntity = ModelEntity.centerSphere()
		movableEntity = ModelEntity.movableSphere()

		centerEntity.addChild(movableEntity)
		movableEntity.position.y = 0.001
	}

	func startTracking() {
		if ImageTrackingProvider.isSupported {
			Task {
				try await session.run([imageInfo])
				for await update in imageInfo.anchorUpdates {
					updateImage(update.anchor)
					modelPosition = movableEntity.position
				}
			}
		}
	}

	private func updateImage(_ anchor: ImageAnchor) {
		if planeAnchors[anchor.id] == nil {
			// Add a new entity to represent this image.
			entityMap[anchor.id] = centerEntity
			planeAnchors[anchor.id] = anchor
		}

		if anchor.isTracked {
			entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
		}
	}
}
