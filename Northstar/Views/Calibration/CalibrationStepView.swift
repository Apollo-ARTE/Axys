//
//  CalibrationStepView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationStepView: View {
	@Binding var step: CalibrationStep

    var body: some View {
		VStack(spacing: 16) {
			Image(systemName: step.systemName)
				.animation(.easeInOut, value: step)
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

			Spacer(minLength: 0)

			VStack {
				Button {
					if let nextStep = step.next {
						step = nextStep
					}
				} label: {
					Text("Done")
						.frame(maxWidth: .infinity)
						.padding(12)
				}
				.tint(.blue)
				.buttonBorderShape(.roundedRectangle(radius: 16))

				Button {
					if let previousStep = step.previous {
						step = previousStep
					}
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
		.frame(maxHeight: 320)
		.padding(32)
    }
}

//#Preview("Place Marker", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
//	CalibrationStepView(step: .placeMarker)
//}


//#Preview("Scan Marker", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
//	CalibrationStepView(step: .scanMarker)
//}
//
//#Preview("Scan Completed", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
//	CalibrationStepView(step: .scanCompleted)
//}
//
//#Preview("Move Robot", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
//	CalibrationStepView(step: .moveRobot)
//}
//
//#Preview("Insert Coordinates", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
//	CalibrationStepView(step: .insertCoordinates)
//}
//
//#Preview("Calibration Completed", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
//	CalibrationStepView(step: .calibrationCompleted)
//}
