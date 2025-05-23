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
            Logger.connection.error("Websocket not initialized.")
            return
        }
        let command = ["command": "ExportUSDZ"]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocketTask.send(message) { error in
                    if let error = error {
                        Logger.connection.error("Error sending message: \(error.localizedDescription)")
                    } else {
                        Logger.connection.info("Command sent: \(command)")
                    }
                }
            }
        } catch {
            Logger.connection.error("Error serializing JSON: \(error.localizedDescription)")
        }
    }
}
