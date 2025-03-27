//
//  CalibrationProcessView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@State private var calibrationStep: CalibrationStep = .placeMarkers

	@State private var coordinates1 = (robot: Coordinate.init(), local: Coordinate.init())
	@State private var coordinates2 = (robot: Coordinate.init(), local: Coordinate.init())
	@State private var coordinates3 = (robot: Coordinate.init(), local: Coordinate.init())

    var body: some View {
		CalibrationStepView(step: $calibrationStep) {
			switch calibrationStep {
			case .insertCoordinates(let number) where number == 1:
				VStack {
					TextField("X", text: $coordinates1.robot.x)
					TextField("Y", text: $coordinates1.robot.y)
					TextField("Z", text: $coordinates1.robot.z)
				}
				.textFieldStyle(.roundedBorder)
			case .insertCoordinates(let number) where number == 2:
				VStack {
					TextField("X", text: $coordinates2.robot.x)
					TextField("Y", text: $coordinates2.robot.y)
					TextField("Z", text: $coordinates2.robot.z)
				}
				.textFieldStyle(.roundedBorder)
			case .insertCoordinates(let number) where number == 3:
				VStack {
					TextField("X", text: $coordinates3.robot.x)
					TextField("Y", text: $coordinates3.robot.y)
					TextField("Z", text: $coordinates3.robot.z)
				}
				.textFieldStyle(.roundedBorder)
			default:
				EmptyView()
			}
		}
		.animation(.snappy, value: calibrationStep)
    }
}

#Preview(windowStyle: .plain) {
    CalibrationProcessView()
		.environment(ImageTracking())
}
