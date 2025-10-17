//
//  LadderBuilder.swift
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

class LadderBuilder {
    
    private let spacing: Double = 2.0  // Spacing between base pairs
    private let width: Double = 8.0    // Width of the ladder
    private let scale: Double = 1.0
    
    func buildLadder(sequence: String, colorScheme: DNAColorScheme, startPosition: Int) -> [SCNNode] {
        var nodes: [SCNNode] = []
        
        let gcContent = SequenceAnalyzer.calculateGCContent(sequence)
        
        for (index, base) in sequence.enumerated() {
            let position = startPosition + index
            let yPosition = Double(index) * spacing
            
            // Left strand base
            let baseNode1 = createBaseNode(
                base: base,
                position: SCNVector3(-width / 2, yPosition, 0),
                colorScheme: colorScheme,
                gcContent: gcContent
            )
            baseNode1.name = "base_\(position)_left"
            nodes.append(baseNode1)
            
            // Right strand base (complementary)
            let complementBase = getComplementaryBase(base)
            let baseNode2 = createBaseNode(
                base: complementBase,
                position: SCNVector3(width / 2, yPosition, 0),
                colorScheme: colorScheme,
                gcContent: gcContent
            )
            baseNode2.name = "base_\(position)_right"
            nodes.append(baseNode2)
            
            // Rung connecting the bases
            let rung = createRung(
                from: SCNVector3(-width / 2, yPosition, 0),
                to: SCNVector3(width / 2, yPosition, 0)
            )
            nodes.append(rung)
            
            // Backbone connections
            if index > 0 {
                let prevY = Double(index - 1) * spacing
                
                // Left backbone
                let backbone1 = createBackbone(
                    from: SCNVector3(-width / 2, prevY, 0),
                    to: SCNVector3(-width / 2, yPosition, 0)
                )
                nodes.append(backbone1)
                
                // Right backbone
                let backbone2 = createBackbone(
                    from: SCNVector3(width / 2, prevY, 0),
                    to: SCNVector3(width / 2, yPosition, 0)
                )
                nodes.append(backbone2)
            }
        }
        
        return nodes
    }
    
    private func createBaseNode(base: Character, position: SCNVector3, colorScheme: DNAColorScheme, gcContent: Double) -> SCNNode {
        let sphere = SCNSphere(radius: 0.5)
        let color = DNASceneManager.colorForBase(base, scheme: colorScheme, gcContent: gcContent)
        sphere.firstMaterial?.diffuse.contents = color
        #if os(macOS)
        sphere.firstMaterial?.specular.contents = NSColor.white
        #else
        sphere.firstMaterial?.specular.contents = UIColor.white
        #endif
        
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        return node
    }
    
    private func createBackbone(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let distance = abs(to.y - from.y)
        
        let cylinder = SCNCylinder(radius: 0.2, height: CGFloat(distance))
        #if os(macOS)
        cylinder.firstMaterial?.diffuse.contents = NSColor.lightGray
        #else
        cylinder.firstMaterial?.diffuse.contents = UIColor.lightGray
        #endif
        
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3(
            from.x,
            (from.y + to.y) / 2,
            0
        )
        
        return node
    }
    
    private func createRung(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let distance = abs(to.x - from.x)
        
        let cylinder = SCNCylinder(radius: 0.1, height: CGFloat(distance))
        #if os(macOS)
        cylinder.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(0.7)
        #else
        cylinder.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.7)
        #endif
        
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3(
            0,
            from.y,
            0
        )
        node.eulerAngles = SCNVector3(0, 0, CGFloat.pi / 2)
        
        return node
    }
    
    private func getComplementaryBase(_ base: Character) -> Character {
        switch base {
        case "A": return "T"
        case "T": return "A"
        case "G": return "C"
        case "C": return "G"
        default: return "N"
        }
    }
}

