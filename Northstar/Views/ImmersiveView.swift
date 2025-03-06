//
//  ImmersiveView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
	@Environment(ImageTracking.self) private var imageTracking

    var body: some View {
        RealityView { content in
			content.add(imageTracking.rootEntity)
		}
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
