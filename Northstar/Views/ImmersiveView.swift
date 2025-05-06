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
                    guard let parent = value.entity.parent else { return }

                    // First time: save the entity's base orientation
                    if appModel.rotationStore[value.entity] == nil {
                        appModel.rotationStore[value.entity] = value.entity.orientation(relativeTo: parent)
                    }

                    // Then apply the delta to that base transform
                    if let base = appModel.rotationStore[value.entity] {
                        let deltaQuat = value.convert(value.rotation, from: .local, to: parent)
                        let newQuat   = deltaQuat * base
                        value.entity.setOrientation(newQuat, relativeTo: parent)
                    }
                }
                .onEnded { value in
                    guard let parent = value.entity.parent,
                          let base   = appModel.rotationStore[value.entity] else { return }

                    let finalDelta = value.convert(value.rotation, from: .local, to: parent)
                    let finalQuat  = finalDelta * base

                    value.entity.setOrientation(finalQuat, relativeTo: parent)

                    // MARK: TO DO ALSO SEND NEW ROTATION TO RHINO
                    // 3) Notify your Rhino/robot backend
//                    rhinoConnectionManager.sendRotationUpdate(
//                        for: value.entity,
//                        newOrientation: finalQuat
//                    )

                    // 4) Clean up so next gesture re‐captures
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
                    if appModel.allowedAxes.contains(.x) { current.x = newPos.x }
                    if appModel.allowedAxes.contains(.y) { current.y = newPos.y }
                    if appModel.allowedAxes.contains(.z) { current.z = newPos.z }
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
