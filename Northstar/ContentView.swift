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

    var body: some View {
        VStack {
            Text("Northstar")
				.font(.largeTitle)

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
