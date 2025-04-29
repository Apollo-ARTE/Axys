//
//  CalibrationStepView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationStepView<Content: View>: View {
	@Environment(\.dismissWindow) private var dismissWindow
	@Environment(CalibrationManager.self) private var calibrationManager
	@Environment(ImageTrackingManager.self) private var imageTrackingManager

	@Binding var step: CalibrationStep

	// swiftlint:disable:next attributes
	@ViewBuilder let content: Content

	private var isNextButtonDisabled: Bool {
		if case .scanMarker(let number) = step {
			let markerName = "marker\(number)"
			return !imageTrackingManager.isMarkerScanned(markerName)
		}
		return false
	}

	var body: some View {
		VStack(spacing: 16) {
			Image(systemName: step.systemName)
				.contentTransition(.symbolEffect(.replace))
				.font(.title2)
				.symbolVariant(.fill)
				.padding()
				.background(.blue, in: .circle)
				.accessibilityHidden(true)

			Text(step.title)
				.font(.title)
			Text(step.description)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)

			content

			VStack {
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
						}
						if let secondPos = imageTrackingManager.secondMarkerEntity?.position {
							calibrationManager.marker2.localX = secondPos.x
							calibrationManager.marker2.localY = secondPos.y
							calibrationManager.marker2.localZ = secondPos.z
						}
						if let thirdPos = imageTrackingManager.thirdMarkerEntity?.position {
							calibrationManager.marker3.localX = thirdPos.x
							calibrationManager.marker3.localY = thirdPos.y
							calibrationManager.marker3.localZ = thirdPos.z
						}

						// Compute the rigid transformation using the new calibration system.
						calibrationManager.calibrate()
						dismissWindow()
					}
				} label: {
					Text("Done")
						.frame(maxWidth: .infinity)
						.padding(12)
				}
				.disabled(isNextButtonDisabled)
				.tint(.blue)
				.buttonBorderShape(.roundedRectangle(radius: 16))

				if let previousStep = step.previous, step != .calibrationCompleted {
					Button {
						step = previousStep
					} label: {
						Text("Go Back")
							.foregroundStyle(.secondary)
							.frame(maxWidth: .infinity)
							.padding(12)
					}
					.disabled(step.previous == nil)
					.buttonBorderShape(.roundedRectangle(radius: 12))
					.buttonStyle(.plain)
				}
			}
		}
		.frame(maxWidth: 280)
		.padding(32)
		.glassBackgroundEffect()
	}
}

#Preview("Place Marker", windowStyle: .plain) {
	@Previewable @State var step: CalibrationStep = .placeMarkers
	CalibrationStepView(step: $step) {}
		.environment(ImageTrackingManager(calibrationManager: .shared))
}
