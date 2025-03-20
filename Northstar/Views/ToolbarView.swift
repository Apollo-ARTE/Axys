//
//  ToolbarView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 19/03/25.
//

import SwiftUI

struct ToolbarView: View {
	@Environment(\.openWindow) private var openWindow
	@Environment(\.dismissWindow) private var dismissWindow

	@State private var showCalibrationWindow = false
	@State private var showInfoPopover = false

    var body: some View {
		HStack {
			Button("Model", systemImage: "cube.fill") {

			}

			Button("Robot's Reach", systemImage: "skew") {

			}

			Divider()
				.frame(height: 40)

			Toggle("Calibrate", systemImage: "perspective", isOn: $showCalibrationWindow)
				.toggleStyle(.button)
				.onChange(of: showCalibrationWindow) {
					if showCalibrationWindow {
						openCalibrationWindow()
					} else {
						dismissCalibrationWindow()
					}
				}

			Toggle("Info", systemImage: "info", isOn: $showInfoPopover)
				.toggleStyle(.button)
				.labelStyle(.iconOnly)
				.popover(isPresented: $showInfoPopover, arrowEdge: .bottom) {
					VStack(alignment: .leading, spacing: 16) {
						Text("Available Data")
							.font(.title2)

						Text("Here is the available data provided by the integration with rhino or the dimensions.")
							.multilineTextAlignment(.leading)
							.foregroundStyle(.secondary)

//						Spacer(minLength: 0)
					}
					.frame(width: 200)
					.padding(32)
				}

		}
		.padding()
		.glassBackgroundEffect()
    }

	private func openCalibrationWindow() {
		openWindow(id: "calibration")
	}

	private func dismissCalibrationWindow() {
		dismissWindow(id: "calibration")
	}
}

#Preview {
    ToolbarView()
}
