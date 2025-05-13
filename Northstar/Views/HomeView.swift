//
//  HomeView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 13/05/25.
//

import SwiftUI

struct HomeView: View {
	@Environment(\.openWindow) private var openWindow
	@Environment(\.dismissWindow) private var dismissWindow
	@Environment(RhinoConnectionManager.self) private var connectionManager

	@State private var isConnected = false

    var body: some View {
		NavigationStack {
			VStack {
				List {
					Section {
						LabeledContent {
							Text("Off")
						} label: {
							Text("Rhino Connection")
							Text("Connect to your local network and run the Rhino Plugin")
								.font(.footnote)
						}
						NavigationLink {
							Text("Models view")
						} label: {
							LabeledContent {
								Text("0")
							} label: {
								Text("Imported Models")
								Text("Run the plugin on Rhino and select your models")
									.font(.footnote)
							}
						}

						Toggle(isOn: $isConnected) {
							Text("Calibration")
							Text("Calibrate your models with real world coordinates")
								.font(.footnote)
						}
						.onChange(of: isConnected) {
							if isConnected {
								connectionManager.connectToWebSocket()
							} else {
								connectionManager.disconnectFromWebSocket()
							}
						}
					} header: {
						header
							.padding(.bottom, 32)
					} footer: {
						footer
							.padding(.top, 32)
					}
				}
				.scrollBounceBehavior(.basedOnSize)
			}
		}
		.padding(32)
		.frame(width: 550, height: 550)
    }

	private var header: some View {
		VStack {
			Text("axys")
				.font(.custom("Boldonse-Regular", size: 40, relativeTo: .extraLargeTitle))
				.frame(maxWidth: .infinity, alignment: .center)
			Text("Bring your 3D Rhino models to life,\naligning them with the real world.")
				.font(.body)
				.multilineTextAlignment(.center)
		}
		.foregroundStyle(.white)
	}

	private var footer: some View {
		Button("Visualize") {
			openToolbar()
		}
		.tint(.blue)
		.buttonStyle(.borderedProminent)
		.buttonBorderShape(.capsule)
		.controlSize(.extraLarge)
		.frame(maxWidth: .infinity, alignment: .center)
	}

	private func openToolbar() {
		Task {
			openWindow(id: "toolbar")
			try await Task.sleep(nanoseconds: 100_000_000)
			dismissWindow()
		}
	}
}

#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 550, height: 550)) {
    HomeView()
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
