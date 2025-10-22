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
    
    private let width: Double = 20.0   // Width of the model (2배 증가: 10.0 -> 20.0)
    private let backboneHeight: Double = 0.4  // Height of backbone elements
    private let baseWidth: Double = 0.6  // Width of base elements
    
    // 화면 높이 기반 동적 간격 계산
    private func calculateOptimalSpacing(sequenceLength: Int, screenHeight: Double) -> Double {
        let availableHeight = screenHeight * 0.85  // 85% 사용 (여백 고려)
        let spacing = availableHeight / Double(sequenceLength)
        
        // 최소/최대 간격 제한
        let minSpacing = 0.8
        let maxSpacing = 3.0
        
        let optimalSpacing = max(min(spacing, maxSpacing), minSpacing)
        
        print("🔍 BallStickBuilder spacing: sequenceLength=\(sequenceLength), screenHeight=\(screenHeight), optimalSpacing=\(optimalSpacing)")
        return optimalSpacing
    }
    
    // 화면 높이 가져오기
    private func getScreenHeight() -> Double {
        #if os(macOS)
        return 800.0  // macOS 기본값
        #else
        let screenBounds = UIScreen.main.bounds
        return Double(screenBounds.height)
        #endif
    }
    
    func buildBallStick(sequence: String, colorScheme: DNAColorScheme, startPosition: Int) -> [SCNNode] {
        var nodes: [SCNNode] = []
        
        // 화면 높이 기반 동적 간격 계산
        let screenHeight = getScreenHeight()
        let spacing = calculateOptimalSpacing(sequenceLength: sequence.count, screenHeight: screenHeight)
        
        // 총 모델 높이와 중앙 정렬을 위한 오프셋 계산
        let totalModelHeight = Double(sequence.count - 1) * spacing
        
        // Create backbone chains (two vertical chains)
        let leftBackbone = createBackboneChain(x: -width/2, spacing: spacing, totalHeight: totalModelHeight)
        let rightBackbone = createBackboneChain(x: width/2, spacing: spacing, totalHeight: totalModelHeight)
        nodes.append(leftBackbone)
        nodes.append(rightBackbone)
        
        // Create base pairs (balls with connecting sticks and labels)
        for (index, base) in sequence.enumerated() {
            let yPosition = Double(index) * spacing - totalModelHeight / 2
            
            // Create base pair
            let basePairNode = createBasePair(base: base, yPosition: yPosition, colorScheme: colorScheme, index: index, totalLength: sequence.count)
            nodes.append(basePairNode)
        }
        
        return nodes
    }
    
    private func createBackboneChain(x: Double, spacing: Double, totalHeight: Double) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.position = SCNVector3(x, 0, 0)
        
        // Create vertical chain of backbone elements
        let sequenceLength = Int(totalHeight / spacing) + 1
        for i in 0..<sequenceLength {
            let yPosition = Double(i) * spacing - totalHeight / 2
            
            // Create backbone sphere
            let sphere = SCNSphere(radius: 0.2)
            sphere.firstMaterial?.diffuse.contents = PlatformColor.systemBlue
            sphere.firstMaterial?.specular.contents = PlatformColor.white
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, yPosition, 0)
            containerNode.addChildNode(sphereNode)
            
            // Create connecting stick (except for the last element)
            if i < sequenceLength - 1 {
                let stick = SCNBox(width: 0.1, height: spacing, length: 0.1, chamferRadius: 0.05)
                stick.firstMaterial?.diffuse.contents = PlatformColor.systemBlue
                
                let stickNode = SCNNode(geometry: stick)
                stickNode.position = SCNVector3(0, yPosition + spacing/2, 0)
                containerNode.addChildNode(stickNode)
            }
        }
        
        return containerNode
    }
    
    private func createBasePair(base: Character, yPosition: Double, colorScheme: DNAColorScheme, index: Int, totalLength: Int) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.position = SCNVector3(0, yPosition, 0)
        
        // Create connecting stick between backbones
        let stick = SCNBox(width: width, height: 0.1, length: 0.1, chamferRadius: 0.05)
        stick.firstMaterial?.diffuse.contents = PlatformColor.systemGray
        
        let stickNode = SCNNode(geometry: stick)
        containerNode.addChildNode(stickNode)
        
        // Create left base (ball with label)
        let leftBase = createBaseWithLabel(base: base, x: -width/2, colorScheme: colorScheme, index: index, totalLength: totalLength)
        containerNode.addChildNode(leftBase)
        
        // Create right base (complementary base)
        let rightBase = getComplementaryBase(base)
        let rightBaseNode = createBaseWithLabel(base: rightBase, x: width/2, colorScheme: colorScheme, index: index, totalLength: totalLength)
        containerNode.addChildNode(rightBaseNode)
        
        return containerNode
    }
    
    private func createBaseWithLabel(base: Character, x: Double, colorScheme: DNAColorScheme, index: Int, totalLength: Int) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.position = SCNVector3(x, 0, 0)
        
        // Create base sphere
        let sphere = SCNSphere(radius: 0.5)
        let color = DNASceneManager.colorForBase(base, scheme: colorScheme, position: index, totalLength: totalLength)
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.specular.contents = PlatformColor.white
        
        let sphereNode = SCNNode(geometry: sphere)
        containerNode.addChildNode(sphereNode)
        
        // Add large, clear text label
        let textGeometry = SCNText(string: String(base), extrusionDepth: 0.3)
        #if os(macOS)
        textGeometry.font = NSFont.systemFont(ofSize: 3.0, weight: .bold)
        #else
        textGeometry.font = UIFont.systemFont(ofSize: 3.0, weight: .bold)
        #endif
        textGeometry.flatness = 0.01
        textGeometry.firstMaterial?.diffuse.contents = PlatformColor.white
        textGeometry.firstMaterial?.emission.contents = PlatformColor(white: 1.0, alpha: 1.0)  // Bright white emission
        textGeometry.firstMaterial?.lightingModel = .constant
        textGeometry.firstMaterial?.isDoubleSided = true
        
        let textNode = SCNNode(geometry: textGeometry)
        // Center the text on the sphere
        let (min, max) = textGeometry.boundingBox
        let textWidth = max.x - min.x
        let textHeight = max.y - min.y
        textNode.position = SCNVector3(-textWidth / 2, -textHeight / 2, 0.7)  // In front of sphere
        textNode.scale = SCNVector3(1.0, 1.0, 1.0)
        textNode.renderingOrder = 1000  // Render on top
        
        containerNode.addChildNode(textNode)
        
        return containerNode
    }
    
    private func getComplementaryBase(_ base: Character) -> Character {
        switch base {
        case "A": return "T"
        case "T": return "A"
        case "G": return "C"
        case "C": return "G"
        default: return base
        }
    }
}
