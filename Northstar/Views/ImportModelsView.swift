//
//  ImportModelsView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 14/05/25.
//

import SwiftUI

struct ImportModelsView: View {
	@Environment(RhinoConnectionManager.self) private var connectionManager

	private var sortedObjects: [RhinoObject] {
		connectionManager.trackedObjects
			.sorted(using: KeyPathComparator(\.importDate, order: .forward))
	}

    var body: some View {
		VStack {
			List {
				Section {
					if !connectionManager.trackedObjects.isEmpty {
						ForEach(sortedObjects, id: \.objectId) { object in
							VStack(alignment: .leading) {
								Text(object.objectName)
								Text(object.objectId)
									.foregroundStyle(.secondary)
									.font(.footnote)
							}
						}
					} else {
						contentUnavailable
					}
				} footer: {
					footer
				}
			}

			Button("Import") {
				connectionManager.sendCommand(value: "ExportUSDZ")
			}
			.buttonBorderShape(.capsule)
			.controlSize(.extraLarge)
		}
		.padding(16)
		.navigationTitle("Imported Models")
    }

	private var contentUnavailable: some View {
		ContentUnavailableView(
			"No imported models",
			systemImage: "document.badge.clock",
			description: Text("Your available models will appear here.")
		)
		.frame(maxWidth: .infinity, alignment: .center)
	}

	private var footer: some View {
		VStack(spacing: 32) {
			Text("Run the Rhino plugin and select the models you want to visualize. Tap `import` when you're ready.")
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity, alignment: .center)
		.padding()
	}
}

#Preview(traits: .fixedLayout(width: 550, height: 550)) {
	NavigationStack {
		ImportModelsView()
	}
	.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
