//
//  CalibrationStepView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationStepView<Content: View>: View {
	@Environment(\.dismissWindow) private var dismissWindow
	@Environment(ImageTracking.self) private var imageTracking
	@Binding var step: CalibrationStep
	@ViewBuilder let content: Content

    var body: some View {
		VStack(spacing: 16) {
			Image(systemName: step.systemName)
				.contentTransition(.symbolEffect(.replace))
				.font(.title2)
				.symbolVariant(.fill)
				.padding()
				.background(.blue, in: .circle)

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
							imageTracking.startTracking()
						case .insertCoordinates:
							break
						default:
							break
						}
						step = nextStep
					} else {
						dismissWindow()
					}
				} label: {
					Text("Done")
						.frame(maxWidth: .infinity)
						.padding(12)
				}
//				.disabled(step == .scanMarker && imageTracking.planeAnchors.isEmpty)
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
	CalibrationStepView(step: $step) {

	}
	.environment(ImageTracking())
}
