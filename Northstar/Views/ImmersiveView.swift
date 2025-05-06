//
//  ImmersiveView.swift
//  Northstar
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
    @State private var printedObject = Entity()
    @State private var robotReachEntity = Entity()
    @State private var virtualLabEntity = Entity()
    @State private var localCoordinates: SIMD3<Float> = .zero
    @State private var robotCoordinates: SIMD3<Float> = .zero

    var body: some View {
        RealityView { content, attachments in
            if let printedObject = try? await ModelEntity.printedObject() {
                self.printedObject = printedObject
            }

            rhinoConnectionManager.object = printedObject

            // Optionally add an attachment to display coordinates.
            if let coordinatesAttachment = attachments.entity(for: "coordinates") {
                coordinatesAttachment.position = [0, 0.4, 0]
                printedObject.addChild(coordinatesAttachment)
            }

            if let robotReachEntity = try? await ModelEntity.robotReach() {
                self.robotReachEntity = robotReachEntity
            }
            if let virtualLabEntity = try? await ModelEntity.virtualLab() {
                self.virtualLabEntity = virtualLabEntity
            }

            content.add(appModel.robotReachRoot)
            content.add(appModel.virtualLabRoot)
            content.add(printedObject)
            content.add(imageTracking.rootEntity)
        } attachments: {
            Attachment(id: "coordinates") {
                VStack {
                    HStack {
                        Text("Local:")
                        Text("X: \(convertToCentimeters(meters: localCoordinates.x))")
                        Text("Y: \(convertToCentimeters(meters: localCoordinates.y))")
                        Text("Z: \(convertToCentimeters(meters: localCoordinates.z))")
                    }
                    HStack {
                        Text("Robot:")
                        Text("X: \(convertToCentimeters(meters: robotCoordinates.x))")
                        Text("Y: \(convertToCentimeters(meters: robotCoordinates.y))")
                        Text("Z: \(convertToCentimeters(meters: robotCoordinates.z))")
                    }
                }
                .padding()
                .glassBackgroundEffect()
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    appModel.selectedEntity = value.entity
                    openWindow(id: "inspector")
                }
        )
        .simultaneousGesture(
            RotateGesture3D()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard
                        let parent = value.entity.parent,
                        let baseQuat = appModel.rotationStore[value.entity] ?? nil
                    else {
                        // on first change, capture base
                        if let parent = value.entity.parent {
                            appModel.rotationStore[value.entity] =
                            value.entity.orientation(relativeTo: parent)
                        }
                        return
                    }

                    // 1) Get the raw delta
                    let rawDelta = value.convert(value.rotation, from: .local, to: parent)

                    // 2) Decompose to Euler angles (in radians)
                    let e = rawDelta.eulerAngles

                    // 3) Zero out any disallowed axes
                    let ex = appModel.allowedRotationAxes.contains(.x) ? e.x : 0
                    let ey = appModel.allowedRotationAxes.contains(.y) ? e.y : 0
                    let ez = appModel.allowedRotationAxes.contains(.z) ? e.z : 0

                    // 4) Rebuild a filtered quaternion (XYZ intrinsic Tait–Bryan)
                    let qx = simd_quatf(angle: ex, axis: SIMD3(1,0,0))
                    let qy = simd_quatf(angle: ey, axis: SIMD3(0,1,0))
                    let qz = simd_quatf(angle: ez, axis: SIMD3(0,0,1))
                    let filteredDelta = qz * qy * qx

                    // 5) Apply filtered delta onto base
                    let newQuat = filteredDelta * baseQuat
                    value.entity.setOrientation(newQuat, relativeTo: parent)

                }
                .onEnded { value in
                    guard
                        let parent = value.entity.parent,
                        let baseQuat = appModel.rotationStore[value.entity]
                    else { return }

                    let rawDelta = value.convert(value.rotation, from: .local, to: parent)
                    let e = rawDelta.eulerAngles

                    let ex = appModel.allowedRotationAxes.contains(.x) ? e.x : 0
                    let ey = appModel.allowedRotationAxes.contains(.y) ? e.y : 0
                    let ez = appModel.allowedRotationAxes.contains(.z) ? e.z : 0

                    let filteredDelta =
                    simd_quatf(angle: ez, axis: [0,0,1]) *
                    simd_quatf(angle: ey, axis: [0,1,0]) *
                    simd_quatf(angle: ex, axis: [1,0,0])

                    let finalQuat = filteredDelta * baseQuat
                    value.entity.setOrientation(finalQuat, relativeTo: parent)

                    // send to Rhino
//                    rhinoConnectionManager.sendRotationUpdate(
//                        for: value.entity,
//                        newOrientation: finalQuat
//                    )

                    appModel.rotationStore.removeValue(forKey: value.entity)
                }
        )
        .simultaneousGesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity

                    guard let parent = entity.parent else { return }
                    let newPos = value.convert(value.location3D,
                                               from: .local,
                                               to: parent)
                    var current = entity.position
                    if appModel.allowedPositionAxes.contains(.x) { current.x = newPos.x }
                    if appModel.allowedPositionAxes.contains(.y) { current.y = newPos.y }
                    if appModel.allowedPositionAxes.contains(.z) { current.z = newPos.z }
                    entity.position = current

                    localCoordinates = current
                    robotCoordinates = calibrationManager.convertLocalToRobot(
                        local: current
                    )
                }
                .onEnded { value in
                    let finalRobot = calibrationManager.convertLocalToRobot(
                        local: value.entity.position
                    )
                    rhinoConnectionManager.sendPositionUpdate(
                        for: value.entity,
                        newPosition: finalRobot
                    )
                    Logger.connection.info(
                        "Sent pos update: local \(value.entity.position), robot \(finalRobot)"
                    )
                }
        )
        .onChange(of: appModel.showRobotReach) { _, newValue in
            toggleRobotReachVisibility(isVisible: newValue)
        }
        .onChange(of: appModel.showVirtualLab) { _, newValue in
            toggleVirtualLabVisibility(isVisible: newValue)
        }
    }

    /// Converts a measurement in meters to a formatted string in centimeters.
    func convertToCentimeters(meters: Float) -> String {
        let measurement = Measurement(value: Double(meters), unit: UnitLength.meters)
        let centimeters = measurement.converted(to: .centimeters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        return formatter.string(from: centimeters)
    }
    private func toggleRobotReachVisibility(isVisible: Bool) {
        if isVisible && calibrationManager.isCalibrationCompleted {
            let position = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
            appModel.robotReachRoot.position = position
            appModel.robotReachRoot.addChild(robotReachEntity)
        } else {
            robotReachEntity.removeFromParent()
        }
    }

    private func toggleVirtualLabVisibility(isVisible: Bool) {
        if isVisible && calibrationManager.isCalibrationCompleted {
            let target = calibrationManager.convertRobotToLocal(robot: [0, 10, 0])
            let from = calibrationManager.convertRobotToLocal(robot: [0, 0, 0])
            appModel.virtualLabRoot.look(at: target, from: from, relativeTo: nil)
            appModel.virtualLabRoot.addChild(virtualLabEntity)
        } else {
            virtualLabEntity.removeFromParent()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel.shared)
        .environment(ImageTrackingManager.shared)
        .environment(CalibrationManager.shared)
        .environment(RhinoConnectionManager(calibrationManager: .shared))
}
