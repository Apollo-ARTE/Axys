//
//  ImageTrackingManager.swift
//  Image Calibration
//
//  Created by Alessandro Bortoluzzi on 05/03/25.
//

import ARKit
import RealityKit

/// Manages image marker tracking during the calibration process using ARKit.
///
/// `ImageTrackingManager` detects and tracks reference images in the AR scene.
/// It updates a root entity with visual markers to represent scanned images
/// and synchronizes this with the current calibration step.
@MainActor
@Observable
class ImageTrackingManager {
	init(calibrationManager: CalibrationManager) {
		self.calibrationManager = calibrationManager
	}

	var calibrationManager: CalibrationManager

	let session = ARKitSession()

	/// The root entity to which marker entities are added in the scene.
	var rootEntity = Entity()

	/// Entity representing the first detected marker, if present.
	var firstMarkerEntity: Entity?

	/// Entity representing the second detected marker, if present.
	var secondMarkerEntity: Entity?

	/// Entity representing the third detected marker, if present.
	var thirdMarkerEntity: Entity?

	/// A set of marker names that have already been scanned.
	private(set) var scannedMarkers: Set<String> = []

	/// A map of active image anchor IDs to their `ImageAnchor` objects.
	private var imageAnchors: [UUID: ImageAnchor] = [:]

	/// A map of anchor IDs to their corresponding scene entities.
	private var entityMap: [UUID: Entity] = [:]

	/// Image tracking provider initialized with reference images from the asset catalog.
	private let imageInfo = ImageTrackingProvider(
		referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "images")
	)

	/// Starts the image tracking session and handles anchor updates.
	///
	/// This method runs the ARKit session with the image tracking provider and listens
	/// for added, updated, or removed anchors. Anchors are handled based on the current
	/// calibration step and associated marker names.
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

	/// Checks whether a marker with the given name has already been scanned.
	///
	/// - Parameter markerName: The name of the marker (e.g., `"marker1"`).
	/// - Returns: `true` if the marker has been scanned, `false` otherwise.
	func isMarkerScanned(_ markerName: String) -> Bool {
		scannedMarkers.contains(markerName)
	}

	/// Updates or adds an image anchor’s corresponding scene entity.
	///
	/// This method creates a marker entity for a new anchor and transforms
	/// it based on the anchor's current pose. It ensures only expected markers
	/// based on the calibration step are processed.
	///
	/// - Parameter anchor: The image anchor that was added or updated.
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

	/// Removes the image anchor and its associated entity from tracking.
	///
	/// - Parameter anchor: The image anchor to remove.
	private func removeImage(_ anchor: ImageAnchor) {
		entityMap.removeValue(forKey: anchor.id)
		imageAnchors.removeValue(forKey: anchor.id)
	}

	/// Extracts the marker number from a marker image name.
	///
	/// - Parameter imageName: The name of the reference image (e.g., `"marker1"`).
	/// - Returns: The numeric suffix as an `Int`, or `nil` if parsing fails.
	private static func markerNumber(from imageName: String) -> Int? {
		guard imageName.hasPrefix("marker") else { return nil }
		return Int(imageName.dropFirst("marker".count))
	}
}
