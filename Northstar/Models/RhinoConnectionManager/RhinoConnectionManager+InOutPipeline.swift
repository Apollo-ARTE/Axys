//  RhinoConnectionManager+InOutPipeline.swift
//  Northstar
//
//  Created by Salvatore Flauto on 01/04/25.
//

import Foundation
import RealityKit

extension RhinoConnectionManager {
	
	func sendExportCommand() {
		guard let webSocketTask = webSocketTask else {
			print("WebSocket non inizializzato.")
			return
		}
		
		let command = ["command": "ExportUSDZ"]
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: command)
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				let message = URLSessionWebSocketTask.Message.string(jsonString)
				webSocketTask.send(message) { error in
					if let error = error {
						print("Errore nell'invio del messaggio: \(error.localizedDescription)")
					} else {
						print("Comando di esportazione inviato.")
					}
				}
			}
		} catch {
			print("Errore nella serializzazione JSON: \(error.localizedDescription)")
		}
	}
	
	
	
//	func getFilePathForRhinoObjects() {
//		let url = Bundle.main.url(forResource: "export", withExtension: "usdz")
//		let entity = try? ModelEntity.load(contentsOf: url!)
//	}
}
