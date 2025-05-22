//  RhinoConnectionManager+InOutPipeline.swift
//  Northstar
//
//  Created by Salvatore Flauto on 01/04/25.
//

import Foundation
import RealityKit
import OSLog

extension RhinoConnectionManager {
	
	func sendExportCommand() {
		guard let webSocketTask = webSocketTask else {
			Logger.connection.error("WebSocket non inizializzato.")
			return
		}
		
		let command = ["command": "ExportUSDZ"]
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: command)
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				let message = URLSessionWebSocketTask.Message.string(jsonString)
				webSocketTask.send(message) { error in
					if let error = error {
						Logger.connection.error("Errore nell'invio del messaggio: \(error.localizedDescription)")
					} else {
						Logger.connection.info("Comando di esportazione inviato.")
					}
				}
			}
		} catch {
			Logger.connection.error("Errore nella serializzazione JSON: \(error.localizedDescription)")
		}
	}
	
	
	
//	func getFilePathForRhinoObjects() {
//		let url = Bundle.main.url(forResource: "export", withExtension: "usdz")
//		let entity = try? ModelEntity.load(contentsOf: url!)
//	}
}
