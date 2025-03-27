//
//  CalibrationProcessView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@Environment(CalibrationManager.self) private var calibrationManager

	@State private var calibrationStep: CalibrationStep = .placeMarkers

    var body: some View {
		@Bindable var calibrationManager = calibrationManager

		CalibrationStepView(step: $calibrationStep) {
			switch calibrationStep {
			case .insertCoordinates(let number) where number == 1:
				CoordinatesInputView(
					x: $calibrationManager.coordinates1.robotX,
					y: $calibrationManager.coordinates1.robotY,
					z: $calibrationManager.coordinates1.robotZ
				)
			case .insertCoordinates(let number) where number == 2:
				CoordinatesInputView(
					x: $calibrationManager.coordinates2.robotX,
					y: $calibrationManager.coordinates2.robotY,
					z: $calibrationManager.coordinates2.robotZ
				)
			case .insertCoordinates(let number) where number == 3:
				CoordinatesInputView(
					x: $calibrationManager.coordinates3.robotX,
					y: $calibrationManager.coordinates3.robotY,
					z: $calibrationManager.coordinates3.robotZ
				)
			default:
				EmptyView()
			}
		}
		.animation(.snappy, value: calibrationStep)
    }
}

#Preview(windowStyle: .plain) {
    CalibrationProcessView()
		.environment(ImageTrackingManager())
		.environment(CalibrationManager())
}
