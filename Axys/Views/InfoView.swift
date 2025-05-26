//
//  InfoView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 21/03/25.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Available Data")
				.font(.title2)
			Text("Here is the available data provided by the integration with rhino or the dimensions.")
				.multilineTextAlignment(.leading)
				.foregroundStyle(.secondary)
		}
		.frame(width: 200)
		.padding(32)
    }
}

#Preview {
    InfoView()
}
