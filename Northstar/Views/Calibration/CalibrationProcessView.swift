//
//  CalibrationProcessView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@Environment(AppModel.self) private var appModel

	@State private var calibrationStep: CalibrationStep = .placeMarkers

    var body: some View {
		@Bindable var appModel = appModel

		CalibrationStepView(step: $calibrationStep) {
			switch calibrationStep {
			case .insertCoordinates(let number) where number == 1:
				VStack {
					TextField("X", text: $appModel.coordinates1.robot.x)
					TextField("Y", text: $appModel.coordinates1.robot.y)
					TextField("Z", text: $appModel.coordinates1.robot.z)
				}
				.textFieldStyle(.roundedBorder)
			case .insertCoordinates(let number) where number == 2:
				VStack {
					TextField("X", text: $appModel.coordinates2.robot.x)
					TextField("Y", text: $appModel.coordinates2.robot.y)
					TextField("Z", text: $appModel.coordinates2.robot.z)
				}
				.textFieldStyle(.roundedBorder)
			case .insertCoordinates(let number) where number == 3:
				VStack {
					TextField("X", text: $appModel.coordinates3.robot.x)
					TextField("Y", text: $appModel.coordinates3.robot.y)
					TextField("Z", text: $appModel.coordinates3.robot.z)
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
		.environment(AppModel())
}
