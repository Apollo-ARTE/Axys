//
//  CalibrationProcessView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@State private var calibrationStep: CalibrationStep = .placeMarker

	@State private var xValue: String = ""
	@State private var yValue: String = ""
	@State private var zValue: String = ""

    var body: some View {
		CalibrationStepView(step: $calibrationStep) {
			if calibrationStep == .insertCoordinates {
				VStack {
					TextField("X", text: $xValue)
					TextField("Y", text: $yValue)
					TextField("Z", text: $zValue)
				}
				.textFieldStyle(.roundedBorder)
			}
		}
		.animation(.snappy, value: calibrationStep)
    }
}

#Preview(windowStyle: .plain) {
    CalibrationProcessView()
}
