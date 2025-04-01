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

	@ViewBuilder let content: Content

	private var isNextButtonDisabled: Bool {
		switch step {
		case .scanMarker(let number):
			let markerName = "marker\(number)"
			return !imageTrackingManager.isMarkerScanned(markerName)
		default:
			return false
		}
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
						switch step {
						case .placeMarkers:
							imageTrackingManager.startTracking()
						default:
							break
						}
						step = nextStep
					} else {
						calibrationManager.coordinates1.localX = imageTrackingManager.firstMarkerEntity?.position.x ?? 0
						calibrationManager.coordinates1.localY = imageTrackingManager.firstMarkerEntity?.position.y ?? 0
						calibrationManager.coordinates1.localZ = imageTrackingManager.firstMarkerEntity?.position.z ?? 0

						calibrationManager.coordinates2.localX = imageTrackingManager.secondMarkerEntity?.position.x ?? 0
						calibrationManager.coordinates2.localY = imageTrackingManager.secondMarkerEntity?.position.y ?? 0
						calibrationManager.coordinates2.localZ = imageTrackingManager.secondMarkerEntity?.position.z ?? 0

						calibrationManager.coordinates3.localX = imageTrackingManager.thirdMarkerEntity?.position.x ?? 0
						calibrationManager.coordinates3.localY = imageTrackingManager.thirdMarkerEntity?.position.y ?? 0
						calibrationManager.coordinates3.localZ = imageTrackingManager.thirdMarkerEntity?.position.z ?? 0

						calibrationManager.computeTransformation()
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
	.environment(ImageTrackingManager())
}
