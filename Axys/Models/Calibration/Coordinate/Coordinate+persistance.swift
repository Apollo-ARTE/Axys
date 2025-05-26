//
//  Coordinate+persistance.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 05/05/25.
//

import Foundation

extension Coordinate {
	/// Saves the current `Coordinate` instance to `UserDefaults` using the provided key.
	///
	/// - Parameter key: The key under which the coordinate will be stored.
	///
	/// This method encodes only the robot coordinates (as per custom `Codable` conformance),
	/// and stores the result in `UserDefaults`. Local coordinates are not persisted.
	func save(key: String) {
		if let encoded = try? JSONEncoder().encode(self) {
			UserDefaults.standard.set(encoded, forKey: key)
		}
	}

	/// Loads a `Coordinate` instance from `UserDefaults` for the given key.
	///
	/// - Parameter key: The key from which the coordinate will be loaded.
	/// - Returns: A `Coordinate` if decoding succeeds, or `nil` if no data is found or decoding fails.
	///
	/// Local coordinates will be reset to `0`, and robot coordinates will default to `0` if missing.
	static func load(key: String) -> Coordinate? {
		if let data = UserDefaults.standard.data(forKey: key),
		   let coordinate = try? JSONDecoder().decode(Coordinate.self, from: data) {
			return coordinate
		}
		return nil
	}
}
