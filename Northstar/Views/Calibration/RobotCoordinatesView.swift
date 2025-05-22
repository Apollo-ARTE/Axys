//
//  RobotCoordinatesView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/05/25.
//

import SwiftUI

struct RobotCoordinatesView: View {
	@Environment(CalibrationManager.self) private var calibrationManager
	enum Marker: CaseIterable, Identifiable {
		case first, second, third

		var id: String {
			title
		}

		var title: String {
			switch self {
			case .first:
				"Marker 1"
			case .second:
				"Marker 2"
			case .third:
				"Marker 3"
			}
		}
	}

	@State private var selectedMarker: Marker = .first

	var body: some View {
		@Bindable var calibrationManager = calibrationManager

		ScrollView {
			VStack(spacing: 16) {
				Picker("Marker", selection: $selectedMarker) {
					ForEach(Marker.allCases) { marker in
						Text(marker.title)
							.tag(marker)
					}
				}
				.pickerStyle(.segmented)

				VStack(alignment: .leading) {
					Text("Robot’s Coordinates (mm)")
						.font(.headline)
					switch selectedMarker {
					case .first:
						CoordinatesInputView(
							x: $calibrationManager.marker1.robotX,
							y: $calibrationManager.marker1.robotY,
							z: $calibrationManager.marker1.robotZ
						)
					case .second:
						CoordinatesInputView(
							x: $calibrationManager.marker2.robotX,
							y: $calibrationManager.marker2.robotY,
							z: $calibrationManager.marker2.robotZ
						)
					case .third:
						CoordinatesInputView(
							x: $calibrationManager.marker3.robotX,
							y: $calibrationManager.marker3.robotY,
							z: $calibrationManager.marker3.robotZ
						)
					}
				}

				VStack(alignment: .leading) {
					Text("Z-origin offset (mm)")
						.font(.headline)
					TextField("Z offset", value: $calibrationManager.zOffset, format: .number)
						.textFieldStyle(.roundedBorder)
						.keyboardType(.decimalPad)
				}
			}
		}
		.scrollBounceBehavior(.basedOnSize)
	}
}

#Preview(windowStyle: .automatic) {
	RobotCoordinatesView()
		.environment(CalibrationManager.shared)
}
