//
//  BallStickBuilder.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation
import SceneKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class BallStickBuilder {
    
    private let spacing: Double = 3.0
    private let helixRadius: Double = 1.5
    private let scale: Double = 10.0
    
    func buildBallStick(sequence: String, colorScheme: DNAColorScheme, startPosition: Int) -> [SCNNode] {
        var nodes: [SCNNode] = []
        
        let basesPerTurn: Double = 10.5
        let angleStep = (2.0 * .pi) / basesPerTurn
        let gcContent = SequenceAnalyzer.calculateGCContent(sequence)
        
        for (index, base) in sequence.enumerated() {
            let position = startPosition + index
            let angle = Double(index) * angleStep
            let height = Double(index) * 0.34 * scale
            
            // Create detailed molecular structure
            let x = helixRadius * cos(angle) * scale
            let z = helixRadius * sin(angle) * scale
            
            // Phosphate group (PO4) - orange sphere
            let phosphate = SCNSphere(radius: 0.4)
            #if os(macOS)
            phosphate.firstMaterial?.diffuse.contents = NSColor.orange
            #else
            phosphate.firstMaterial?.diffuse.contents = UIColor.orange
            #endif
            let phosphateNode = SCNNode(geometry: phosphate)
            phosphateNode.position = SCNVector3(x * 1.2, height, z * 1.2)
            nodes.append(phosphateNode)
            
            // Sugar (deoxyribose) - gray sphere
            let sugar = SCNSphere(radius: 0.35)
            #if os(macOS)
            sugar.firstMaterial?.diffuse.contents = NSColor.gray
            #else
            sugar.firstMaterial?.diffuse.contents = UIColor.gray
            #endif
            let sugarNode = SCNNode(geometry: sugar)
            sugarNode.position = SCNVector3(x, height, z)
            nodes.append(sugarNode)
            
            // Base - colored sphere
            let color = DNASceneManager.colorForBase(base, scheme: colorScheme, gcContent: gcContent)
            let baseSphere = SCNSphere(radius: 0.5)
            baseSphere.firstMaterial?.diffuse.contents = color
            let baseNode = SCNNode(geometry: baseSphere)
            baseNode.position = SCNVector3(x * 0.7, height, z * 0.7)
            baseNode.name = "base_\(position)"
            nodes.append(baseNode)
            
            // Bonds between atoms (sticks)
            // Phosphate to Sugar
            let bond1 = createBond(
                from: phosphateNode.position,
                to: sugarNode.position,
                color: .white
            )
            nodes.append(bond1)
            
            // Sugar to Base
            let bond2 = createBond(
                from: sugarNode.position,
                to: baseNode.position,
                color: .white
            )
            nodes.append(bond2)
            
            // Backbone connection (phosphate to next sugar)
            if index > 0 {
                let prevAngle = Double(index - 1) * angleStep
                let prevHeight = Double(index - 1) * 0.34 * scale
                let prevX = helixRadius * cos(prevAngle) * scale * 1.2
                let prevZ = helixRadius * sin(prevAngle) * scale * 1.2
                
                let backboneBond = createBond(
                    from: SCNVector3(prevX, prevHeight, prevZ),
                    to: phosphateNode.position,
                    color: .lightGray
                )
                nodes.append(backboneBond)
            }
        }
        
        return nodes
    }
    
    #if os(macOS)
    private func createBond(from: SCNVector3, to: SCNVector3, color: NSColor) -> SCNNode {
        let vector = SCNVector3(
            to.x - from.x,
            to.y - from.y,
            to.z - from.z
        )
        
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        let cylinder = SCNCylinder(radius: 0.08, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = color
        
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        
        if distance > 0 {
            node.eulerAngles = SCNVector3(
                .pi / 2,
                acos(vector.y / distance),
                atan2(vector.x, vector.z)
            )
        }
        
        return node
    }
    #else
    private func createBond(from: SCNVector3, to: SCNVector3, color: UIColor) -> SCNNode {
        let vector = SCNVector3(
            to.x - from.x,
            to.y - from.y,
            to.z - from.z
        )
        
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        let cylinder = SCNCylinder(radius: 0.08, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = color
        
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        
        if distance > 0 {
            node.eulerAngles = SCNVector3(
                .pi / 2,
                acos(vector.y / distance),
                atan2(vector.x, vector.z)
            )
        }
        
        return node
    }
    #endif
}

