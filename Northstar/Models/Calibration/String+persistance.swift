//
//  String+persistance.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 14/05/25.
//

import Foundation

extension String {
	func save(key: String) {
		UserDefaults.standard.set(self, forKey: key)
	}

	static func load(key: String) -> String? {
		if let data = UserDefaults.standard.string(forKey: key) {
			return data
		} else {
			return nil
		}
	}
}
