//
//  ImportModelsView.swift
//  Axys
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
        @Bindable var connectionManager = connectionManager
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

            Button {
                connectionManager.sendCommand(value: "ExportUSDZ")
            } label: {
                if connectionManager.isImportingObjects {
                    ProgressView()
                } else {
                    Text("Import")
                        .padding()
                }
            }
            .controlSize(.extraLarge)
			.alert(
				"Import Error",
				isPresented: $connectionManager.errorAlertShown,
				presenting: connectionManager.rhinoErrorMessage
			) { _ in
                Button("OK") {
                    connectionManager.errorAlertShown = false
                }
            } message: { error in
                Text(error)
            }
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
