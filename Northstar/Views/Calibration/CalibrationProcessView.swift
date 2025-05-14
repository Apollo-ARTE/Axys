//
//  CalibrationProcessView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@Environment(CalibrationManager.self) private var calibrationManager

    var body: some View {
		@Bindable var calibrationManager = calibrationManager

		CalibrationStepView(step: $calibrationManager.calibrationStep) {
			switch calibrationManager.calibrationStep {
			case .zOffset:
				TextField("Z offset", value: $calibrationManager.zOffset, format: .number)
					.textFieldStyle(.roundedBorder)
					.keyboardType(.decimalPad)
			case .insertCoordinates(let number) where number == 1:
				CoordinatesInputView(
					x: $calibrationManager.marker1.robotX,
					y: $calibrationManager.marker1.robotY,
					z: $calibrationManager.marker1.robotZ
				)
			case .insertCoordinates(let number) where number == 2:
				CoordinatesInputView(
					x: $calibrationManager.marker2.robotX,
					y: $calibrationManager.marker2.robotY,
					z: $calibrationManager.marker2.robotZ
				)
			case .insertCoordinates(let number) where number == 3:
				CoordinatesInputView(
					x: $calibrationManager.marker3.robotX,
					y: $calibrationManager.marker3.robotY,
					z: $calibrationManager.marker3.robotZ
				)
			default:
				EmptyView()
			}
		}
		.animation(.snappy, value: calibrationManager.calibrationStep)
		.navigationTitle("Calibration")
    }
}

#Preview(windowStyle: .plain) {
    CalibrationProcessView()
		.environment(ImageTrackingManager(calibrationManager: .shared))
		.environment(CalibrationManager.shared)
}
