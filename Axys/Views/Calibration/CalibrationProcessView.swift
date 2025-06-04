//
//  CalibrationProcessView.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@Environment(CalibrationManager.self) private var calibrationManager

    var body: some View {
		@Bindable var calibrationManager = calibrationManager

		CalibrationStepView(step: $calibrationManager.calibrationStep) {
			if calibrationManager.calibrationStep == .insertCoordinates {
				RobotCoordinatesView()
			} else {
				MarkersScanView(step: calibrationManager.calibrationStep)
			}
		}
		.animation(.snappy, value: calibrationManager.calibrationStep)
		.navigationTitle("Calibration")
    }
}

#Preview(windowStyle: .automatic) {
    CalibrationProcessView()
		.environment(ImageTrackingManager(calibrationManager: .shared))
		.environment(CalibrationManager.shared)
}
