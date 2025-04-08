//
//  InspectorView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 08/04/25.
//

import SwiftUI

struct InspectorView: View {
	enum Axes {
		case x, y, z
	}

	@Environment(RhinoConnectionManager.self) private var connectionManager

	var body: some View {
		@Bindable var connectionManager = connectionManager
		VStack {
			TextField("X", value: objectX(axes: .x), format: .number)
			TextField("Y", value: objectX(axes: .y), format: .number)
			TextField("Z", value: objectX(axes: .z), format: .number)
		}
		.textFieldStyle(.roundedBorder)
		.keyboardType(.numbersAndPunctuation)
		.padding()
	}

	private func objectX(axes: Axes) -> Binding<Float> {
		Binding {
			let position = connectionManager.object?.position
			switch axes {
			case .x:
				return position?.x ?? 0
			case .y:
				return position?.y ?? 0
			case .z:
				return position?.z ?? 0
			}
		} set: { value in
			switch axes {
			case .x:
				connectionManager.object?.position.x = value
			case .y:
				connectionManager.object?.position.y = value
			case .z:
				connectionManager.object?.position.z = value
			}
		}
	}
}

#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 300, height: 200)) {
	InspectorView()
		.environment(RhinoConnectionManager.init(calibrationManager: .shared))
}
