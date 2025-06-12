//
//  CalibrationStep.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

/// Represents the different steps involved in the calibration workflow.
///
/// Each step includes an identifier, UI-related properties (icon, title, description),
/// and navigation helpers to move between steps.
///
/// - Steps include placing markers, scanning specific markers, completion, and coordinate insertion.
enum CalibrationStep: Identifiable, Equatable {
	case placeMarkers
	case scanMarker(number: Int)
	case scanCompleted
	case insertCoordinates

	var id: String {
		switch self {
		case .placeMarkers:
			"placeMarkers"
		case .scanMarker(let number):
			"scanMarker\(number)"
		case .scanCompleted:
			"scanCompleted"
		case .insertCoordinates:
			"insertCoordinates"
		}
	}

	static var allCases: [CalibrationStep] {
		[
			.placeMarkers,
			.scanMarker(number: 1), .scanMarker(number: 2), .scanMarker(number: 3),
			.scanCompleted,
			.insertCoordinates
		]
	}

	var systemName: String {
		switch self {
		case .placeMarkers:
			"qrcode"
		case .scanMarker:
			"qrcode.viewfinder"
		case .scanCompleted:
			"qrcode.viewfinder"
		case .insertCoordinates:
			"rotate.3d"
		}
	}

	var title: LocalizedStringKey {
		switch self {
		case .placeMarkers:
			"Place the Markers"
		case .scanMarker(let number):
			"Scan Marker \(number)"
		case .scanCompleted:
			"Scan Completed"
		case .insertCoordinates:
			"Robot’s Coordinates"
		}
	}

	var description: LocalizedStringKey {
		switch self {
		case .placeMarkers:
			"Position the markers where it remains visible and accessible for the robot."
		case .scanMarker(let number):
			"Use your Vision Pro to scan marker \(number), ensuring it is clearly visible."
		case .scanCompleted:
			"Now move the robot to the center of each marker and get it's coordinates."
		case .insertCoordinates:
			"Enter the robot's position coordinates for markers."
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
