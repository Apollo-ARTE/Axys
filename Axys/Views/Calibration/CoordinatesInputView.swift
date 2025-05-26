//
//  CoordinatesInputView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 27/03/25.
//

import SwiftUI

struct CoordinatesInputView: View {
	@Binding var x: Float
	@Binding var y: Float
	@Binding var z: Float

    var body: some View {
		VStack(spacing: 2) {
			TextField("X (mm)", value: $x, format: .number)
			TextField("Y (mm)", value: $y, format: .number)
			TextField("Z (mm)", value: $z, format: .number)
		}
		.textFieldStyle(.roundedBorder)
		.keyboardType(.numbersAndPunctuation)
    }
}

#Preview {
	@Previewable @State var x: Float = 0
	@Previewable @State var y: Float = 0
	@Previewable @State var z: Float = 0

	CoordinatesInputView(x: $x, y: $y, z: $z)
}
