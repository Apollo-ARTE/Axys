//
//  CalibrationStepView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationStepView<Content: View>: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(CalibrationManager.self) private var calibrationManager
	@Environment(ImageTrackingManager.self) private var imageTrackingManager

	@Binding var step: CalibrationStep

	// swiftlint:disable:next attributes
	@ViewBuilder let content: Content

	@Namespace private var namespace

	private var isNextButtonDisabled: Bool {
		if case .scanMarker(let number) = step {
			let markerName = "marker\(number)"
			return !imageTrackingManager.isMarkerScanned(markerName)
		}
		return false
	}

	var body: some View {
		VStack(spacing: 0) {
			content
			doneButton
		}
		.toolbar {
			if calibrationManager.calibrationStep != .placeMarkers {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Reset", systemImage: "arrow.clockwise") {
						calibrationManager.reset()
						imageTrackingManager.reset()
					}
					.labelStyle(.iconOnly)
					.buttonStyle(.bordered)
				}
			}
		}
		.padding()
	}

	private var doneButton: some View {
		Button {
			if let nextStep = step.next {
				// If we're in the placeMarkers step, start image tracking.
				if case .placeMarkers = step {
					imageTrackingManager.startTracking()
				}
				step = nextStep
			} else {
				// When done, update each marker's local coordinates from the imageTrackingManager.
				if let firstPos = imageTrackingManager.firstMarkerEntity?.position {
					calibrationManager.marker1.localX = firstPos.x
					calibrationManager.marker1.localY = firstPos.y
					calibrationManager.marker1.localZ = firstPos.z
					calibrationManager.marker1.save(key: "marker1")
				}
				if let secondPos = imageTrackingManager.secondMarkerEntity?.position {
					calibrationManager.marker2.localX = secondPos.x
					calibrationManager.marker2.localY = secondPos.y
					calibrationManager.marker2.localZ = secondPos.z
					calibrationManager.marker2.save(key: "marker2")
				}
				if let thirdPos = imageTrackingManager.thirdMarkerEntity?.position {
					calibrationManager.marker3.localX = thirdPos.x
					calibrationManager.marker3.localY = thirdPos.y
					calibrationManager.marker3.localZ = thirdPos.z
					calibrationManager.marker3.save(key: "marker3")
				}

				// Compute the rigid transformation using the new calibration system.
				calibrationManager.calibrate()
				dismiss()
			}
		} label: {
			Text(step == .insertCoordinates ? "Done" : "Next")
				.padding(.horizontal, 32)
		}
		.buttonBorderShape(.capsule)
		.buttonStyle(.borderedProminent)
		.controlSize(.extraLarge)
		.disabled(isNextButtonDisabled)
		.tint(.blue)
	}
}

#Preview("Place Marker", windowStyle: .plain) {
	@Previewable @State var step: CalibrationStep = .placeMarkers
	CalibrationStepView(step: $step) {}
		.environment(ImageTrackingManager(calibrationManager: .shared))
		.environment(CalibrationManager.shared)
}
