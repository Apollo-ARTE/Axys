//
//  AxisControl.swift
//  Axys
//
//  Created by Guillermo Kramsky on 05/05/25.
//

import SwiftUI

struct AxisControl: View {
    let axis: Axes
    @Binding var allowedAxes: AxisOptions
    let position: Binding<Float>

    var body: some View {
        HStack {
            Button {
                allowedAxes.toggle(axis.option)
            } label: {
                Text(axis.label)
                    .font(.caption)
                    .padding()
                    .background(allowedAxes.contains(axis.option) ? Color.blue : Color.clear)
                    .clipShape(Circle())
            }
            .buttonBorderShape(.circle)

			TextField(
				axis.label,
				value: position,
				format: .number.precision(.fractionLength(0))
			)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numbersAndPunctuation)
        }
    }
}
#Preview {
    AxisControl(axis: .x, allowedAxes: .constant(.all), position: .constant(0))
}
