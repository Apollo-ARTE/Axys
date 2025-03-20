//
//  CalibrationProcessView.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 20/03/25.
//

import SwiftUI

struct CalibrationProcessView: View {
	@State private var calibrationStep: CalibrationStep = .placeMarker

    var body: some View {
		CalibrationStepView(step: calibrationStep)
    }
}

#Preview {
    CalibrationProcessView()
}
