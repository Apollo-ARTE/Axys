//
//  ModelEntity+PritedObject.swift
//  Northstar
//
//  Created by Alessandro Bortoluzzi on 08/04/25.
//

import RealityKit

extension ModelEntity {

    static func robotReach() async throws -> ModelEntity? {
        guard let object = try? await ModelEntity(named: "robot_reach") else {
            return nil
        }
        object.name = "robot_reach_blue"
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .blue)
        material.faceCulling = .none
        object.model?.materials = [material]
        object.components.set(OpacityComponent(opacity: 0.2))
        object.transform.scale = [0.001, 0.001, 0.001]
        return object
    }

    static func virtualLab() async throws -> ModelEntity? {
        guard let object = try? await ModelEntity(named: "virtual_lab_empty") else {
            return nil
        }
        object.name = "virtual_lab"
        object.transform.scale = [0.001, 0.001, 0.001]

        return object
    }
}
