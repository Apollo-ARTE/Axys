//
//  ContentView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
	@Environment(ImageTracking.self) private var imageTracking

	@State private var xValue: String = ""
	@State private var yValue: String = ""
	@State private var zValue: String = ""

    var body: some View {
        VStack {
            Text("Northstar")
				.font(.largeTitle)

            ToggleImmersiveSpaceButton()

			VStack {
				TextField("X", text: $xValue)
				TextField("Y", text: $yValue)
				TextField("Z", text: $zValue)
			}
			.frame(maxWidth: 200)

			Button("Set") {
				let xFloat: Float = Float(xValue) ?? 0
				let yFloat: Float = Float(yValue) ?? 0
				let zFloat: Float = Float(zValue) ?? 0

				imageTracking.movableEntity.position = [xFloat/100, yFloat/100, zFloat/100]
			}
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
