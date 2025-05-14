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
	@Environment(AppModel.self) private var appModel
	@Environment(RhinoConnectionManager.self) private var connectionManager

	@State private var isCalibrated = false
	@State private var showConnectionView = false
	@State private var showCalibrationView = false

    var body: some View {
		@Bindable var appModel = appModel
		NavigationStack {
			VStack {
				List {
					Section {
						LabeledContent {
							Text(connectionManager.isConnected ? "On" : "Off")
						} label: {
							Text("Rhino Connection")
							Text("Connect to your local network and run the Rhino Plugin")
								.font(.footnote)
						}
						NavigationLink {
							ImportModelsView()
						} label: {
							LabeledContent {
								Text(connectionManager.trackedObjects?.count ?? 0, format: .number)
							} label: {
								Text("Imported Models")
								Text("Run the plugin on Rhino and select your models")
									.font(.footnote)
							}
						}

						Toggle(isOn: $appModel.showCalibrationWindow) {
							Text("Calibration")
							Text("Calibrate your models with real world coordinates")
								.font(.footnote)
						}
						.onChange(of: appModel.showCalibrationWindow) {
							if appModel.showCalibrationWindow {
								showCalibrationView = true
							} else {
								showCalibrationView = false
							}
						}
						.disabled(appModel.immersiveSpaceState == .inTransition)
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
			.navigationDestination(isPresented: $showConnectionView) {
				ConnectionView()
			}
			.navigationDestination(isPresented: $showCalibrationView) {
				CalibrationProcessView()
			}
		}
		.padding(16)
		.frame(width: 550, height: 500)
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
			if connectionManager.isConnected {
				openToolbar()
			} else {
				showConnectionView = true
			}
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

	private func openCalibrationWindow() {
		openWindow(id: "calibration")
	}

	private func dismissCalibrationWindow() {
		dismissWindow(id: "calibration")
	}
}

#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 550, height: 550)) {
	HomeView()
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
