//
//  CalibrationStepView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationStepView: View {
	let step: CalibrationStep

    var body: some View {
		VStack(spacing: 16) {
			Image(systemName: step.systemName)
				.font(.title2)
				.symbolVariant(.fill)
				.padding()
				.background(.blue, in: .circle)

			Text(step.title)
					.font(.title)
			Text(step.description)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)

			VStack {
				Button {

				} label: {
					Text("Done")
						.frame(maxWidth: .infinity)
						.padding(12)
				}
				.tint(.blue)
				.buttonBorderShape(.roundedRectangle(radius: 16))

				Button {

				} label: {
					Text("Go Back")
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity)
						.padding(12)
				}
				.buttonBorderShape(.roundedRectangle(radius: 12))
				.buttonStyle(.plain)
			}
		}
		.padding(32)
    }
}

#Preview("Place Marker", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
	CalibrationStepView(step: .placeMarker)
}


#Preview("Scan Marker", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
	CalibrationStepView(step: .scanMarker)
}

#Preview("Scan Completed", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
	CalibrationStepView(step: .scanCompleted)
}

#Preview("Move Robot", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
	CalibrationStepView(step: .moveRobot)
}

#Preview("Insert Coordinates", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
	CalibrationStepView(step: .insertCoordinates)
}

#Preview("Calibration Completed", windowStyle: .automatic, traits: .fixedLayout(width: 320, height: 380)) {
	CalibrationStepView(step: .calibrationCompleted)
}
