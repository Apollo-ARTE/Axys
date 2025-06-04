//
//  MarkersScanView.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 20/05/25.
//

import SwiftUI

struct MarkersScanView: View {
	@Environment(ImageTrackingManager.self) private var imageTrackingManager
	let step: CalibrationStep

	private func imageBackground(isComplete: Bool) -> AnyShapeStyle {
		isComplete ? AnyShapeStyle(.blue) : AnyShapeStyle(.ultraThinMaterial)
	}

    var body: some View {
		VStack(spacing: 32) {
			HStack(spacing: 16) {
				stepImage(
					name: step.systemName,
					isFilled: imageTrackingManager.firstMarkerEntity != nil
				)
				stepImage(
					name: step.systemName,
					isFilled: imageTrackingManager.secondMarkerEntity != nil
				)
				stepImage(
					name: step.systemName,
					isFilled: imageTrackingManager.thirdMarkerEntity != nil
				)
			}

			VStack {
				Text(step.title)
					.font(.largeTitle)
				Text(step.description)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.frame(maxWidth: 300)
			}
			.padding(.bottom, 52)
		}
    }

	private func stepImage(name: String, isFilled: Bool) -> some View {
		Image(systemName: name)
			.contentTransition(.symbolEffect(.replace))
			.font(.largeTitle)
			.symbolVariant(.fill)
			.padding()
			.background(imageBackground(isComplete: isFilled), in: .circle)
			.accessibilityHidden(true)
	}
}

#Preview {
	MarkersScanView(step: .insertCoordinates)
}
