//
//  HelixBuilder.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation
import SceneKit
import simd

// MARK: - SCNVector3 Extensions
extension SCNVector3 {
    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    var simd: simd_float3 {
        simd_float3(x, y, z)
    }
    
    init(_ simd: simd_float3) {
        self.init(simd.x, simd.y, simd.z)
    }
    
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
}

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class HelixBuilder {
    
    // DNA helix parameters (B-DNA)
    private let basesPerTurn: Double = 10.5
    private let risePerBase: Double = 0.34  // nm
    private let helixRadius: Double = 1.0    // nm
    private let scale: Double = 5.0          // Scale factor for visualization (reduced for better visibility)
    private let backboneRadius: CGFloat = 0.55
    private let baseHalfThickness: CGFloat = 0.32
    private let baseHalfDepth: CGFloat = 0.42
    private let baseChamfer: CGFloat = 0.18
    private let hydrogenGap: Float = 0.3
    private let hydrogenBondRadius: CGFloat = 0.12  // Increased for better visibility
    private let baseLabelOutset: Float = 1.2
    private let baseLabelScale: Float = 0.8
    
    func buildHelix(sequence: String, colorScheme: DNAColorScheme, startPosition: Int) -> [SCNNode] {
        var nodes: [SCNNode] = []
        
        // Step 1: Create continuous helix curves for both strands
        let strand1Points = createHelixCurve(sequenceLength: sequence.count, strandOffset: 0)
        let strand2Points = createHelixCurve(sequenceLength: sequence.count, strandOffset: .pi)
        
        // Step 2: Create smooth backbone segments along the curves
        let backbone1 = createSmoothBackbone(points: strand1Points, strandName: "strand1", radius: backboneRadius)
        let backbone2 = createSmoothBackbone(points: strand2Points, strandName: "strand2", radius: backboneRadius)
        nodes.append(backbone1)
        nodes.append(backbone2)
        
        // Step 3: Create base blocks positioned on the backbone curves
        let gcContent = SequenceAnalyzer.calculateGCContent(sequence)
        
        for (index, base) in sequence.enumerated() {
            let position = startPosition + index
            let complementBase = getComplementaryBase(base)
            
            
            // Create base pair connecting the two backbones
            let basePair = createBasePair(
                base1: base,
                base2: complementBase,
                position1: strand1Points[index],
                position2: strand2Points[index],
                colorScheme: colorScheme,
                gcContent: gcContent,
                position: position,
                index: index  // Add index for naming
            )
            basePair.name = "basepair_\(index)"  // Name for identification
            nodes.append(basePair)
        }
        
        return nodes
    }
    
    // MARK: - Step 1 Helper Methods
    
    private func createHelixCurve(sequenceLength: Int, strandOffset: Double) -> [SCNVector3] {
        var points: [SCNVector3] = []
        let angleStep = (2.0 * .pi) / basesPerTurn
        
        for i in 0..<sequenceLength {
            let angle = Double(i) * angleStep + strandOffset
            let height = Double(i) * risePerBase * scale
            
            let x = helixRadius * cos(angle) * scale
            let z = helixRadius * sin(angle) * scale
            
            points.append(SCNVector3(x, height, z))
        }
        
        return points
    }
    
    private func createSmoothBackbone(points: [SCNVector3], strandName: String, radius: CGFloat) -> SCNNode {
        let parent = SCNNode()
        parent.name = "backbone_\(strandName)"
        
        for i in 1..<points.count {
            let segment = createBackboneSegment(from: points[i-1], to: points[i], radius: radius)
            parent.addChildNode(segment)
        }
        
        return parent
    }
    
    private func createBackboneSegment(from: SCNVector3, to: SCNVector3, radius: CGFloat) -> SCNNode {
        let distance = (to - from).length()
        let capsule = SCNCapsule(capRadius: radius, height: CGFloat(distance))
        capsule.radialSegmentCount = 24
        capsule.heightSegmentCount = 12
        
        // Set physically based material
        #if os(macOS)
        capsule.firstMaterial?.diffuse.contents = NSColor(red: 0.06, green: 0.54, blue: 0.97, alpha: 1)
        #else
        capsule.firstMaterial?.diffuse.contents = UIColor(red: 0.06, green: 0.54, blue: 0.97, alpha: 1)
        #endif
        capsule.firstMaterial?.lightingModel = SCNMaterial.LightingModel.phong
        
        let node = SCNNode(geometry: capsule)
        node.position = (from + to) * 0.5
        node.look(at: to, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 1, 0))
        
        return node
    }
    
    private func calculateTotalCurveLength(points: [SCNVector3]) -> Double {
        var totalLength: Double = 0
        for i in 1..<points.count {
            let from = points[i-1]
            let to = points[i]
            let distance = Double(sqrt(
                pow(Double(to.x - from.x), 2) + 
                pow(Double(to.y - from.y), 2) + 
                pow(Double(to.z - from.z), 2)
            ))
            totalLength += distance
        }
        return totalLength
    }
    
    private func createBasePair(
        base1: Character,
        base2: Character,
        position1: SCNVector3,
        position2: SCNVector3,
        colorScheme: DNAColorScheme,
        gcContent: Double,
        position: Int,
        index: Int
    ) -> SCNNode {
        let basePairNode = SCNNode()
        basePairNode.name = "basePair_\(position)"
        
        let color1 = DNASceneManager.colorForBase(base1, scheme: colorScheme, gcContent: gcContent)
        let color2 = DNASceneManager.colorForBase(base2, scheme: colorScheme, gcContent: gcContent)
        
        let p1 = position1.simd
        let p2 = position2.simd
        let vector = p2 - p1
        let distance = simd_length(vector)
        guard distance > 0.0001 else { return basePairNode }
        
        let direction = simd_normalize(vector)
        let excluded = Float(backboneRadius * 2) + hydrogenGap
        let usable = max(0.15, distance - excluded)
        let halfLength = usable / 2
        let baseRadius = Float(backboneRadius)
        
        let center1 = p1 + direction * (baseRadius + halfLength / 2)
        let center2 = p2 - direction * (baseRadius + halfLength / 2)
        
        let baseNode1 = createBaseHalf(
            length: halfLength,
            color: color1,
            center: center1,
            direction: direction
        )
        baseNode1.name = "base_\(index)_strand1"
        basePairNode.addChildNode(baseNode1)
        
        let baseNode2 = createBaseHalf(
            length: halfLength,
            color: color2,
            center: center2,
            direction: -direction
        )
        baseNode2.name = "base_\(index)_strand2"
        basePairNode.addChildNode(baseNode2)
        
        let innerStart = center1 + direction * (halfLength / 2)
        let innerEnd = center2 - direction * (halfLength / 2)
        
        let hBond = createHydrogenBond(
            from: SCNVector3(innerStart),
            to: SCNVector3(innerEnd),
            basePair: "\(base1)\(base2)"
        )
        basePairNode.addChildNode(hBond)
        
        // Add readable AGCT labels on the outer face of each base block
        let centerPoint = (p1 + p2) * 0.5
        let radial1Source = center1 - centerPoint
        let radial1 = simd_length(radial1Source) > 0.0001 ? simd_normalize(radial1Source) : simd_float3(0, 1, 0)
        let labelNode1 = createBaseLabel(
            base: base1,
            baseCenter: center1,
            radialDirection: radial1,
            color: color1
        )
        labelNode1.name = "label_\(index)_strand1"
        basePairNode.addChildNode(labelNode1)
        
        let radial2Source = center2 - centerPoint
        let radial2 = simd_length(radial2Source) > 0.0001 ? simd_normalize(radial2Source) : simd_float3(0, 1, 0)
        let labelNode2 = createBaseLabel(
            base: base2,
            baseCenter: center2,
            radialDirection: radial2,
            color: color2
        )
        labelNode2.name = "label_\(index)_strand2"
        basePairNode.addChildNode(labelNode2)
        
        return basePairNode
    }
    
    private func createBaseHalf(
        length: Float,
        color: PlatformColor,
        center: simd_float3,
        direction: simd_float3
    ) -> SCNNode {
        let geometry = SCNBox(
            width: CGFloat(length),
            height: baseHalfThickness,
            length: baseHalfDepth,
            chamferRadius: baseChamfer
        )
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.specular.contents = PlatformColor.white
        geometry.firstMaterial?.shininess = 120
        geometry.firstMaterial?.lightingModel = .physicallyBased
        
        let node = SCNNode(geometry: geometry)
        node.simdPosition = center
        
        let localAxis = simd_float3(1, 0, 0)
        let targetAxis = simd_normalize(direction)
        let cross = simd_cross(localAxis, targetAxis)
        let crossLength = simd_length(cross)
        
        if crossLength > 1e-6 {
            let normalizedCross = cross / crossLength
            let angle = acos(max(-1.0, min(1.0, simd_dot(localAxis, targetAxis))))
            node.simdOrientation = simd_quatf(angle: angle, axis: normalizedCross)
        } else if simd_dot(localAxis, targetAxis) < 0 {
            node.simdOrientation = simd_quatf(angle: .pi, axis: simd_float3(0, 1, 0))
        }
        
        return node
    }
    
    private func createBaseLabel(base: Character, baseCenter: simd_float3, radialDirection: simd_float3, color: PlatformColor) -> SCNNode {
        let textGeometry = SCNText(string: String(base), extrusionDepth: 0.05)
        textGeometry.flatness = 0.15
        #if os(macOS)
        textGeometry.font = NSFont.systemFont(ofSize: 0.9, weight: .heavy)
        #else
        textGeometry.font = UIFont.systemFont(ofSize: 0.9, weight: .heavy)
        #endif
        textGeometry.firstMaterial?.diffuse.contents = PlatformColor.white
        textGeometry.firstMaterial?.specular.contents = PlatformColor.white
        textGeometry.firstMaterial?.emission.contents = PlatformColor(white: 0.2, alpha: 1.0)
        textGeometry.firstMaterial?.lightingModel = .constant
        textGeometry.firstMaterial?.isDoubleSided = true
        
        let glyphNode = SCNNode(geometry: textGeometry)
        glyphNode.scale = SCNVector3(baseLabelScale, baseLabelScale, baseLabelScale)
        glyphNode.renderingOrder = 2048
        glyphNode.castsShadow = false
        
        let bounds = textGeometry.boundingBox
        let xOffset = (bounds.max.x + bounds.min.x) / 2
        let yOffset = bounds.min.y
        glyphNode.pivot = SCNMatrix4MakeTranslation(xOffset, yOffset, 0)
        
        let container = SCNNode()
        let outwardOffset = Float(baseHalfDepth) * 0.5 + baseLabelOutset
        let upwardOffset = simd_float3(0, 0.3, 0) // 위로 0.3 유닛 올리기
        container.simdPosition = baseCenter + radialDirection * outwardOffset + upwardOffset
        container.addChildNode(glyphNode)
        
        let forward = simd_float3(0, 0, 1)
        let rotationAxis = simd_cross(forward, radialDirection)
        let axisLength = simd_length(rotationAxis)
        if axisLength > 1e-6 {
            let normalizedAxis = rotationAxis / axisLength
            let angle = acos(max(-1.0, min(1.0, simd_dot(forward, radialDirection))))
            container.simdOrientation = simd_quatf(angle: angle, axis: normalizedAxis)
        }
        
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        container.constraints = [billboard]
        
        return container
    }
    
    private func createBackbone(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let vector = SCNVector3(
            to.x - from.x,
            to.y - from.y,
            to.z - from.z
        )
        
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        // Create smoother backbone (like in the image)
        let cylinder = SCNCylinder(radius: 0.3, height: CGFloat(distance))
        #if os(macOS)
        cylinder.firstMaterial?.diffuse.contents = NSColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0) // Bright cyan blue
        cylinder.firstMaterial?.specular.contents = NSColor.white
        #else
        cylinder.firstMaterial?.diffuse.contents = UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0) // Bright cyan blue
        cylinder.firstMaterial?.specular.contents = UIColor.white
        #endif
        cylinder.firstMaterial?.shininess = 80
        
        let node = SCNNode(geometry: cylinder)
        
        // Position cylinder between the two points
        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        
        // Rotate cylinder to align with vector
        node.eulerAngles = SCNVector3(
            .pi / 2,
            acos(vector.y / distance),
            atan2(vector.x, vector.z)
        )
        
        return node
    }
    
    private func createHydrogenBond(from: SCNVector3, to: SCNVector3, basePair: String) -> SCNNode {
        let vector = SCNVector3(
            to.x - from.x,
            to.y - from.y,
            to.z - from.z
        )
        
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        // Hydrogen bonds shown as light gray cylinders between paired bases
        let cylinder = SCNCylinder(radius: hydrogenBondRadius, height: CGFloat(distance))
        #if os(macOS)
        cylinder.firstMaterial?.diffuse.contents = NSColor(white: 0.7, alpha: 1.0)  // Light gray
        cylinder.firstMaterial?.specular.contents = NSColor.white
        cylinder.firstMaterial?.emission.contents = NSColor(white: 0.1, alpha: 1.0)  // Slight glow
        #else
        cylinder.firstMaterial?.diffuse.contents = UIColor(white: 0.7, alpha: 1.0)  // Light gray
        cylinder.firstMaterial?.specular.contents = UIColor.white
        cylinder.firstMaterial?.emission.contents = UIColor(white: 0.1, alpha: 1.0)  // Slight glow
        #endif
        cylinder.firstMaterial?.shininess = 80
        
        let node = SCNNode(geometry: cylinder)
        
        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )
        
        node.eulerAngles = SCNVector3(
            .pi / 2,
            acos(vector.y / distance),
            atan2(vector.x, vector.z)
        )
        
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
