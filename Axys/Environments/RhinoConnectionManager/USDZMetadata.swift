//
//  USDZMetadata.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 04/06/25.
//

/// A model representing metadata for a USDZ file sent over the WebSocket connection.
///
/// This struct is used to decode JSON messages that describe an incoming USDZ asset,
/// including its name, size, and a timestamp.
struct USDZMetadata: Decodable {
	let type: String
	let fileName: String
	let size: Int
	let timestamp: Int
}
