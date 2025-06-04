//
//  ImmersiveView.swift
//  Axys
//
//  Created by Alessandro Bortoluzzi on 06/03/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
import simd

struct ImmersiveView: View {
	@Environment(\.openWindow) private var openWindow
	@Environment(AppModel.self) private var appModel
	@Environment(ImageTrackingManager.self) private var imageTracking
	@Environment(RhinoConnectionManager.self) private var rhinoConnectionManager
	@Environment(CalibrationManager.self) private var calibrationManager
	
	@State private var rootObject = Entity()
	@State private var robotReachEntity = Entity()
	@State private var virtualLabEntity = Entity()
	@State private var localCoordinates: SIMD3<Float> = .zero
	@State private var robotCoordinates: SIMD3<Float> = .zero
	
	var body: some View {
		RealityView { content in
			if let robotReachEntity = try? await ModelEntity.robotReach() {
				self.robotReachEntity = robotReachEntity
			}
			if let virtualLabEntity = try? await ModelEntity.virtualLab() {
				self.virtualLabEntity = virtualLabEntity
			}
			
			content.add(appModel.robotReachRoot)
			content.add(appModel.virtualLabRoot)
			content.add(rhinoConnectionManager.rhinoRootEntity)
			content.add(imageTracking.rootEntity)
		} update: { content in
			if appModel.showModels { // Uncomment line for testing without calibration
				if let model = content.entities.first(where: { $0.name == "rhino_root" }) {
					model.children.forEach { rhinoObject in
						rhinoObject.transform.scale = [0.001, 0.001, 0.001]
						//                        Logger.views.debug("Showing object: \(rhinoObject.name) at position \(rhinoObject.position)")
					}
				}
			} else {
				if let model = content.entities.first(where: { $0.name == "rhino_root" }) {
					model.children.forEach { rhinoObject in
						//                        Logger.views.debug("Hiding object: \(rhinoObject.name)")
						rhinoObject.transform.scale = [0, 0, 0]
					}
				}
			}
		}
		.gesture(dragGesture3D())
		.gesture(tapGesture())
		.gesture(rotateGesture3D())
		.onChange(of: appModel.showRobotReach) { _, newValue in
			toggleRobotReachVisibility(isVisible: newValue)
		}
		.onChange(of: appModel.showVirtualLab) { _, newValue in
			toggleVirtualLabVisibility(isVisible: newValue)
		}
	}
	
	private func toggleRobotReachVisibility(isVisible: Bool) {
		if isVisible {
			let position = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
			appModel.robotReachRoot.position = position
			appModel.robotReachRoot.addChild(robotReachEntity)
		} else {
			robotReachEntity.removeFromParent()
		}
	}
	
	private func toggleVirtualLabVisibility(isVisible: Bool) {
		if isVisible {
			let target = calibrationManager.convertRobotToLocal(robot: [0, 10, 0])
			let from = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
			appModel.virtualLabRoot.look(at: target, from: from, relativeTo: nil)
			appModel.virtualLabRoot.addChild(virtualLabEntity)
		} else {
			virtualLabEntity.removeFromParent()
		}
	}
	
	private func rotateGesture3D() -> some Gesture {
		RotateGesture3D()
			.targetedToAnyEntity()
			.onChanged { value in
				guard let parent = value.entity.parent else { return }
				
				let baseQuat = appModel.rotationStore[value.entity] ?? {
					let orientation = value.entity.orientation(relativeTo: parent)
					appModel.rotationStore[value.entity] = orientation
					return orientation
				}()
				
				let rawDelta = value.convert(value.rotation, from: .local, to: parent)
				let e = rawDelta.eulerAngles
				
				if let allowedRotationAxes = value.entity.components[AxesComponent.self]?.allowedRotationAxes {
					let ex = allowedRotationAxes.contains(.x) ? e.x : 0
					let ey = allowedRotationAxes.contains(.y) ? e.y : 0
					let ez = allowedRotationAxes.contains(.z) ? e.z : 0
					
					let filteredDelta = simd_quatf(angle: ez, axis: [0, 0, 1]) *
					simd_quatf(angle: ey, axis: [0, 1, 0]) *
					simd_quatf(angle: ex, axis: [1, 0, 0])
					
					value.entity.setOrientation(filteredDelta * baseQuat, relativeTo: parent)
				}
			}
			.onEnded { value in
				guard let parent = value.entity.parent,
					  let baseQuat = appModel.rotationStore[value.entity]
				else { return }
				
				let rawDelta = value.convert(value.rotation, from: .local, to: parent)
				let e = rawDelta.eulerAngles
				
				if let allowedRotationAxes = value.entity.components[AxesComponent.self]?.allowedRotationAxes {
					let ex = allowedRotationAxes.contains(.x) ? e.x : 0
					let ey = allowedRotationAxes.contains(.y) ? e.y : 0
					let ez = allowedRotationAxes.contains(.z) ? e.z : 0
					
					let filteredDelta = simd_quatf(angle: ez, axis: [0, 0 ,1]) *
					simd_quatf(angle: ey, axis: [0, 1, 0]) *
					simd_quatf(angle: ex, axis: [1, 0, 0])
					
					let finalQuat = filteredDelta * baseQuat
					value.entity.setOrientation(finalQuat, relativeTo: parent)
					appModel.rotationStore.removeValue(forKey: value.entity)
				}
			}
	}
	
	private func dragGesture3D() -> some Gesture {
		DragGesture()
			.targetedToAnyEntity()
			.onChanged { value in
				guard let parent = value.entity.parent else { return }
				
				let newPos = value.convert(value.location3D, from: .local, to: parent)
				var current = value.entity.position
				
				if let allowedPositionAxes = value.entity.components[AxesComponent.self]?.allowedPositionAxes {
					if allowedPositionAxes.contains(.x) { current.x = newPos.x }
					if allowedPositionAxes.contains(.y) { current.y = newPos.y }
					if allowedPositionAxes.contains(.z) { current.z = newPos.z }
					
					value.entity.position = current
				}
				
				localCoordinates = current
				robotCoordinates = calibrationManager.convertLocalToRobot(local: current)
			}
			.onEnded { value in
				let finalRobot = calibrationManager.convertLocalToRobot(local: value.entity.position)
				rhinoConnectionManager.sendPositionUpdate(for: value.entity, newPosition: finalRobot)
				Logger.connection.info("Sent pos update: local \(value.entity.position), robot \(finalRobot)")
			}
	}
	
	private func tapGesture() -> some Gesture {
		TapGesture()
			.targetedToAnyEntity()
			.onEnded { value in
				appModel.selectedEntities.append(value.entity)
				let id = String(value.entity.id)
				openWindow(value: id)
			}
	}
}

#Preview(immersionStyle: .mixed) {
	ImmersiveView()
		.environment(AppModel.shared)
		.environment(ImageTrackingManager.init(calibrationManager: .shared))
		.environment(CalibrationManager.shared)
		.environment(RhinoConnectionManager(calibrationManager: .shared))
}
