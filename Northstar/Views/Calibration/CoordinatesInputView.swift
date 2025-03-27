//
//  CoordinatesInputView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import SwiftUI

struct CoordinatesInputView: View {
	@Binding var x: String
	@Binding var y: String
	@Binding var z: String

    var body: some View {
		VStack {
			TextField("X", text: $x)
			TextField("Y", text: $y)
			TextField("Z", text: $z)
		}
		.textFieldStyle(.roundedBorder)
    }
}

#Preview {
	@Previewable @State var x: String = ""
	@Previewable @State var y: String = ""
	@Previewable @State var z: String = ""

	CoordinatesInputView(x: $x, y: $y, z: $z)
}
