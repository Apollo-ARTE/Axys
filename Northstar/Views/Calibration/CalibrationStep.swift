//
//  CalibrationStep.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUICore

enum CalibrationStep: String, Identifiable, CaseIterable {
	case placeMarker = "placeMarker"
	case scanMarker = "scanMarker"
	case scanCompleted = "scanCompleted"
	case moveRobot = "moveRobot"
	case insertCoordinates = "insertCoordinates"
	case calibrationCompleted = "calibrationCompleted"

	var id: String {
		self.rawValue
	}

	var systemName: String {
		switch self {
		case .placeMarker:
			"qrcode"
		case .scanMarker:
			"qrcode.viewfinder"
		case .scanCompleted:
			"checkmark.circle"
		case .moveRobot:
			"move.3d"
		case .insertCoordinates:
			"rotate.3d"
		case .calibrationCompleted:
			"checkmark.circle"
		}
	}

	var title: LocalizedStringKey {
		switch self {
		case .placeMarker:
			"Place the Marker"
		case .scanMarker:
			"Scan the Marker"
		case .scanCompleted:
			"Scan Completed"
		case .moveRobot:
			"Move the Robot"
		case .insertCoordinates:
			"Robot’s Coordinates"
		case .calibrationCompleted:
			"Calibration Completed"
		}
	}

	var description: LocalizedStringKey {
		switch self {
		case .placeMarker:
			"Position the marker where it remains visible and accessible for the robot."
		case .scanMarker:
			"Use your Vision Pro to scan the marker, ensuring it is clearly visible."
		case .scanCompleted:
			"Use your Vision Pro to scan the marker, ensuring it is clearly visible."
		case .moveRobot:
			"Align the robot to the center of the marker to set new coordinates."
		case .insertCoordinates:
			"Enter the updated origin point for precise positioning."
		case .calibrationCompleted:
			"Your models will now appear exactly where they will be printed."
		}
	}
}
