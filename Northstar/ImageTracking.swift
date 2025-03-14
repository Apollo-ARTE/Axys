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

	var rootEntity = ModelEntity()
	var planeAnchors: [UUID: ImageAnchor] = [:]
	var entityMap: [UUID: Entity] = [:]

	let imageInfo = ImageTrackingProvider(
		referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "images")
	)

	init() {
		startTracking()
	}

	func startTracking() {
		if ImageTrackingProvider.isSupported {
			Task {
				try await session.run([imageInfo])
				for await update in imageInfo.anchorUpdates {
					updateImage(update.anchor)
				}
			}
		}
	}

	func updateImage(_ anchor: ImageAnchor) {
		if planeAnchors[anchor.id] == nil {
			// Add a new entity to represent this image.
			let sphere = ModelEntity.centerSphere()
			sphere.name = "centerSphere"
			entityMap[anchor.id] = sphere
			planeAnchors[anchor.id] = anchor
			rootEntity.addChild(sphere)
		}

		if anchor.isTracked {
			entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
		}
	}
}
