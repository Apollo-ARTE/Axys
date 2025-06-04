//
//  ConnectionView.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 14/05/25.
//

import SwiftUI

struct ConnectionView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(RhinoConnectionManager.self) private var connectionManager

	@State private var showWrongIPAlert: Bool = false

	var body: some View {
		@Bindable var connectionManager = connectionManager
		List {
			Section {
				TextField("192.168.1.2", text: $connectionManager.ipAddress)
					.keyboardType(.decimalPad)
			} header: {
				Text("IP Address")
			} footer: {
				Text("As soon as you are connected, run the Rhino Plugin to import and track the models you want to visualize.")
			}

			Section {} footer: {
				Button("Connect") {
					if connectionManager.isValidIPAddress() {
						connectionManager.connectToWebSocket()
					} else {
						showWrongIPAlert = true
					}
				}
				.tint(.blue)
				.buttonStyle(.borderedProminent)
				.buttonBorderShape(.capsule)
				.controlSize(.extraLarge)
				.frame(maxWidth: .infinity, alignment: .center)
				.disabled(connectionManager.isConnected)
			}
		}
		.navigationTitle("Rhino Connection")
		.alert("Wrong IP", isPresented: $showWrongIPAlert) {
		} message: {
			Text("Make sure to input the correct IP address of your Rhino server and try again.")
		}
		.onChange(of: connectionManager.isConnected) { _, newValue in
			if newValue {
				dismiss()
			}
		}
	}
}

#Preview {
	NavigationStack {
		ConnectionView()
	}
	.environment(RhinoConnectionManager(calibrationManager: .shared))
}
