//
//  CalibrationStep.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUICore

enum CalibrationStep: Identifiable, Equatable {
	case placeMarkers
	case scanMarker(number: Int)
	case scanCompleted
	case insertCoordinates(number: Int)
	case calibrationCompleted

	var id: String {
		switch self {
		case .placeMarkers:
			"placeMarkers"
		case .scanMarker(let number):
			"scanMarker\(number)"
		case .scanCompleted:
			"scanCompleted"
		case .insertCoordinates(let number):
			"insertCoordinates\(number)"
		case .calibrationCompleted:
			"calibrationCompleted"
		}
	}

	static var allCases: [CalibrationStep] {
		[
			.placeMarkers,
			.scanMarker(number: 1), .scanMarker(number: 2), .scanMarker(number: 3),
			.scanCompleted,
			.insertCoordinates(number: 1),
			.insertCoordinates(number: 2),
			.insertCoordinates(number: 3),
			.calibrationCompleted
		]
	}

	var systemName: String {
		switch self {
		case .placeMarkers:
			"qrcode"
		case .scanMarker:
			"qrcode.viewfinder"
		case .scanCompleted:
			"checkmark.circle"
		case .insertCoordinates:
			"rotate.3d"
		case .calibrationCompleted:
			"checkmark.circle"
		}
	}

	var title: LocalizedStringKey {
		switch self {
		case .placeMarkers:
			"Place the Marker"
		case .scanMarker(let number):
			"Scan the Marker \(number)"
		case .scanCompleted:
			"Scan Completed"
		case .insertCoordinates:
			"Robot’s Coordinates"
		case .calibrationCompleted:
			"Calibration Completed"
		}
	}

	var description: LocalizedStringKey {
		switch self {
		case .placeMarkers:
			"Position the marker where it remains visible and accessible for the robot."
		case .scanMarker(let number):
			"Use your Vision Pro to scan the marker \(number), ensuring it is clearly visible."
		case .scanCompleted:
			"Use your Vision Pro to scan the marker, ensuring it is clearly visible."
		case .insertCoordinates(let number):
			"Enter the robot's position coordinates for marker \(number)."
		case .calibrationCompleted:
			"Your models will now appear exactly where they will be printed."
		}
	}

	var next: CalibrationStep? {
		guard let currentIndex = Self.allCases.firstIndex(of: self), currentIndex < Self.allCases.count - 1 else {
			return nil
		}
		return Self.allCases[currentIndex + 1]
	}

	var previous: CalibrationStep? {
		guard let currentIndex = Self.allCases.firstIndex(of: self), currentIndex > 0 else {
			return nil
		}
		return Self.allCases[currentIndex - 1]
	}
}
