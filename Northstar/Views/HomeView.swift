//
//  HomeView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 13/05/25.
//

import SwiftUI

struct HomeView: View {
	@Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
	@Environment(\.openImmersiveSpace) private var openImmersiveSpace
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
						NavigationLink {
							ConnectionView()
						} label: {
							VStack(alignment: .leading) {
								Text("\(connectionManager.isConnected ? "Connected to Rhino" : "Connect to Rhino")")
								Text("Connect to your local network and run the Rhino Plugin")
									.font(.footnote)
									.foregroundStyle(.secondary)
							}
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
						.disabled(!connectionManager.isConnected)

						Toggle(isOn: $appModel.showCalibrationWindow) {
							Text("Calibration")
							Text("Calibrate your models with real world coordinates")
								.font(.footnote)
						}
						.tint(.blue)
						.onChange(of: appModel.showCalibrationWindow) {
							if appModel.showCalibrationWindow {
								showCalibrationView = true
							} else {
								showCalibrationView = false
							}
						}
						.disabled(appModel.immersiveSpaceState == .inTransition)
						.disabled(!connectionManager.isConnected)
					} header: {
						header
							.padding(.vertical, 32)
					} footer: {
						footer
							.padding(.vertical, 32)
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
		.frame(width: 550, height: 550)
		.task {
			await toggleImmersiveSpace()
		}
    }

	private var header: some View {
		VStack {
			Text("axys")
				.font(.custom("Boldonse-Regular", size: 50, relativeTo: .extraLargeTitle))
				.frame(maxWidth: .infinity, alignment: .center)
//			Text("Bring your 3D Rhino models to life,\naligning them with the real world.")
//				.font(.body)
//				.multilineTextAlignment(.center)
		}
		.foregroundStyle(.white)
	}

	private var footer: some View {
		Button("Visualize") {
			if connectionManager.isConnected {
				openWindow(id: "toolbar")
			} else {
				showConnectionView = true
			}
		}
		.tint(.blue)
		.buttonStyle(.borderedProminent)
		.buttonBorderShape(.capsule)
		.controlSize(.extraLarge)
		.frame(maxWidth: .infinity, alignment: .center)
		.disabled(!connectionManager.isConnected)
		.disabled(connectionManager.trackedObjects?.isEmpty ?? true)
	}

	@MainActor
	private func toggleImmersiveSpace() async {
		switch appModel.immersiveSpaceState {
		case .open:
			appModel.immersiveSpaceState = .inTransition
			await dismissImmersiveSpace()
		case .closed:
			appModel.immersiveSpaceState = .inTransition
			switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
			case .opened:
				break
			case .userCancelled, .error:
				fallthrough
			@unknown default:
				appModel.immersiveSpaceState = .closed
			}
		case .inTransition:
			break
		}
	}
}

#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 550, height: 550)) {
	HomeView()
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
