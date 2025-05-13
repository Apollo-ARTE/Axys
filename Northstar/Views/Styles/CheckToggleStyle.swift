//
//  CheckToggleStyle.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 13/05/25.
//

import SwiftUI

struct CircularToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
		VStack {
			Button {
				configuration.isOn.toggle()
			} label: {
				Image(systemName: "circle")
					.foregroundStyle(.clear)
					.overlay {
						configuration.label
							.labelStyle(.iconOnly)
							.font(.largeTitle)
					}
					.padding(32)
					.background {
						if configuration.isOn {
							Circle()
								.foregroundStyle(.blue)
						} else {
							Circle()
								.foregroundStyle(.regularMaterial)
						}
					}
			}
			configuration.label
				.labelStyle(.titleOnly)
				.font(.subheadline)
		}
    }
}

extension ToggleStyle where Self == CircularToggleStyle {
	static var circluar: CircularToggleStyle { .init() }
}
