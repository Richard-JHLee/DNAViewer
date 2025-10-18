//
//  DNASceneManager.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation
import SceneKit
import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
#else
import UIKit
typealias PlatformColor = UIColor
#endif

enum DNARepresentation: String, CaseIterable {
    case doubleHelix = "Double Helix"
    case ladder = "Ladder"
    case ballAndStick = "Ball & Stick"
    case sequenceOnly = "Sequence"
}

enum DNAColorScheme: String, CaseIterable {
    case byBase = "By Base"
    case byStrand = "By Strand"
    case uniform = "Uniform"
    case gcContent = "GC Content"
}

class DNASceneManager: ObservableObject {
    @Published var currentRepresentation: DNARepresentation = .doubleHelix
    @Published var colorScheme: DNAColorScheme = .byBase
    @Published var selectedRange: Range<Int>?
    @Published var highlightedFeatures: [GeneFeature] = []
    @Published var isAnimating = false
    @Published var selectedBaseIndex: Int?
    
    var scene: SCNScene
    private var cameraNode: SCNNode
    private var helixNodes: [SCNNode] = []
    private var currentSequence: DNASequence?
    
    // Display settings
    var displayStart: Int = 0
    var displayLength: Int = 100 // Show only subset for performance
    var currentGroup: Int = 1
    var totalGroups: Int = 1
    var groupSize: Int = 40
    
    init() {
        scene = SCNScene()
        
        // Set dark navy background (like in the image)
        #if os(macOS)
        scene.background.contents = NSColor(red: 0.03, green: 0.08, blue: 0.15, alpha: 1.0)
        #else
        scene.background.contents = UIColor(red: 0.03, green: 0.08, blue: 0.15, alpha: 1.0)
        #endif
        
        // Setup camera with HDR and bloom
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.3
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 20)  // Better viewing angle
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))    // Look at center
        scene.rootNode.addChildNode(cameraNode)
        
        // Setup lighting
        setupLighting()
    }
    
    private func setupLighting() {
        // Ambient light (reduced for dark background)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        #if os(macOS)
        ambientLight.light?.color = NSColor(white: 0.3, alpha: 1.0)
        #else
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        #endif
        scene.rootNode.addChildNode(ambientLight)
        
        // Main directional light (key light from top-front)
        let mainLight = SCNNode()
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.intensity = 2000
        #if os(macOS)
        mainLight.light?.color = NSColor.white
        #else
        mainLight.light?.color = UIColor.white
        #endif
        mainLight.eulerAngles = SCNVector3(x: -.pi / 4, y: .pi / 6, z: 0)
        scene.rootNode.addChildNode(mainLight)
        
        // Fill light (softer)
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 800
        #if os(macOS)
        fillLight.light?.color = NSColor(white: 0.8, alpha: 1.0)
        #else
        fillLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        #endif
        fillLight.eulerAngles = SCNVector3(x: .pi / 6, y: -.pi / 4, z: 0)
        scene.rootNode.addChildNode(fillLight)
    }
    
    func loadSequence(_ sequence: DNASequence) {
        currentSequence = sequence
        
        // Calculate groups based on sequence ID and length
        calculateGroups(for: sequence)
        
        rebuildScene()
    }
    
    private func calculateGroups(for sequence: DNASequence) {
        let sequenceId = sequence.name.lowercased()
        
        // ID별로 적절한 그룹 크기 결정 (메모리 절약을 위해 더 작게)
        if sequenceId.contains("brca1") {
            groupSize = 20  // BRCA1: 7088개 -> 355개 그룹 (각 그룹당 20개)
        } else if sequenceId.contains("tp53") {
            groupSize = 20  // TP53: 393개 -> 20개 그룹
        } else if sequenceId.contains("cftr") {
            groupSize = 25  // CFTR: 1480개 -> 60개 그룹
        } else if sequenceId.contains("huntingtin") {
            groupSize = 30  // Huntingtin: 3144개 -> 105개 그룹
        } else {
            // 기본값: 시퀀스 길이에 따라 동적 계산
            if sequence.length > 1000 {
                groupSize = 50
            } else if sequence.length > 500 {
                groupSize = 40
            } else if sequence.length > 100 {
                groupSize = 30
            } else {
                groupSize = sequence.length
            }
        }
        
        // 그룹 수 계산
        if sequence.length <= groupSize {
            totalGroups = 1
            currentGroup = 1
            displayStart = 0
            displayLength = sequence.length
        } else {
            totalGroups = (sequence.length + groupSize - 1) / groupSize  // 올림 계산
            currentGroup = 1
            displayStart = 0
            displayLength = min(groupSize, sequence.length)
        }
        
        print("🧬 \(sequence.name): \(sequence.length) bases -> \(totalGroups) groups (size: \(groupSize))")
    }
    
    func loadGroup(_ group: Int) {
        guard let sequence = currentSequence else {
            print("⚠️ loadGroup: No sequence loaded")
            return
        }
        guard group >= 1 && group <= totalGroups else {
            print("⚠️ loadGroup: Invalid group \(group) (total: \(totalGroups))")
            return
        }
        
        print("🔄 Loading group \(group) (was: \(currentGroup))")
        
        // UI 업데이트를 명시적으로 트리거
        objectWillChange.send()
        
        // 즉시 currentGroup 업데이트 (UI가 바로 반응하도록)
        self.currentGroup = group
        self.displayStart = (group - 1) * self.groupSize
        self.displayLength = min(self.groupSize, sequence.length - self.displayStart)
        print("📊 Group \(group): start=\(self.displayStart), length=\(self.displayLength)")
        print("✅ currentGroup updated to: \(self.currentGroup)")
        
        // Scene 재구성은 비동기로
        DispatchQueue.main.async { [weak self] in
            self?.rebuildScene()
        }
    }
    
    func nextGroup() {
        if currentGroup < totalGroups {
            loadGroup(currentGroup + 1)
        }
    }
    
    func previousGroup() {
        if currentGroup > 1 {
            loadGroup(currentGroup - 1)
        }
    }
    
    func rebuildScene() {
        // Clear existing nodes
        helixNodes.forEach { $0.removeFromParentNode() }
        helixNodes.removeAll()
        
        guard let sequence = currentSequence else { return }
        
        // Build according to current representation
        switch currentRepresentation {
        case .doubleHelix:
            buildDoubleHelix(sequence: sequence)
        case .ladder:
            buildLadder(sequence: sequence)
        case .ballAndStick:
            buildBallAndStick(sequence: sequence)
        case .sequenceOnly:
            break // 2D view, no 3D rendering
        }
    }
    
    func buildDoubleHelix(sequence: DNASequence) {
        let helixBuilder = HelixBuilder()
        let displaySeq = getDisplaySequence(sequence)
        
        print("🧬 Building double helix with sequence: \(displaySeq)")
        print("🧬 Sequence length: \(displaySeq.count)")
        print("🧬 Display start: \(displayStart), display length: \(displayLength)")
        print("🧬 Full sequence length: \(sequence.length)")
        
        let nodes = helixBuilder.buildHelix(
            sequence: displaySeq,
            colorScheme: colorScheme,
            startPosition: displayStart
        )
        
        print("🧬 Created \(nodes.count) nodes for DNA helix")
        
        for node in nodes {
            scene.rootNode.addChildNode(node)
            helixNodes.append(node)
        }
        
        print("🧬 DNA helix build complete. Total nodes in scene: \(helixNodes.count)")
    }
    
    func buildLadder(sequence: DNASequence) {
        let ladderBuilder = LadderBuilder()
        let displaySeq = getDisplaySequence(sequence)
        
        let nodes = ladderBuilder.buildLadder(
            sequence: displaySeq,
            colorScheme: colorScheme,
            startPosition: displayStart
        )
        
        for node in nodes {
            scene.rootNode.addChildNode(node)
            helixNodes.append(node)
        }
    }
    
    func buildBallAndStick(sequence: DNASequence) {
        let ballStickBuilder = BallStickBuilder()
        let displaySeq = getDisplaySequence(sequence)
        
        let nodes = ballStickBuilder.buildBallStick(
            sequence: displaySeq,
            colorScheme: colorScheme,
            startPosition: displayStart
        )
        
        for node in nodes {
            scene.rootNode.addChildNode(node)
            helixNodes.append(node)
        }
    }
    
    private func getDisplaySequence(_ sequence: DNASequence) -> String {
        let start = min(displayStart, sequence.length)
        let end = min(displayStart + displayLength, sequence.length)
        
        let startIndex = sequence.sequence.index(sequence.sequence.startIndex, offsetBy: start)
        let endIndex = sequence.sequence.index(sequence.sequence.startIndex, offsetBy: end)
        
        return String(sequence.sequence[startIndex..<endIndex])
    }
    
    func highlightRange(_ range: Range<Int>) {
        selectedRange = range
        // TODO: Add visual highlight to the selected bases
    }
    
    func animateRotation() {
        isAnimating.toggle()
        
        if isAnimating {
            let rotation = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8)
            )
            
            for node in helixNodes {
                node.runAction(rotation, forKey: "rotation")
            }
        } else {
            for node in helixNodes {
                node.removeAction(forKey: "rotation")
            }
        }
    }
    
    func zoomToRange(_ range: Range<Int>) {
        displayStart = range.lowerBound
        displayLength = range.count
        rebuildScene()
    }
    
    func resetView() {
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 50)
        cameraNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
    }
    
    func selectBase(at index: Int) {
        print("🎯 Selecting base at index: \(index)")
        selectedBaseIndex = index
        highlightSelectedBase()
    }
    
    private func highlightSelectedBase() {
        guard let selectedIndex = selectedBaseIndex else {
            // Clear all highlights
            clearHighlights()
            return
        }
        
        // Clear previous highlights
        clearHighlights()
        
        // Find and highlight the selected base node
        let relativeIndex = selectedIndex - displayStart
        print("🔍 Looking for base at index \(selectedIndex), displayStart=\(displayStart), relativeIndex=\(relativeIndex)")
        print("🔍 displayLength=\(displayLength), helixNodes count=\(helixNodes.count)")
        
        guard relativeIndex >= 0 && relativeIndex < displayLength else {
            print("⚠️ Selected base \(selectedIndex) is not in current display range (\(displayStart)..<\(displayStart + displayLength))")
            return
        }
        
        // Search for base pair node at this position
        // basepair nodes are direct children in helixNodes array
        var found = false
        print("🔍 Total helix nodes: \(helixNodes.count)")
        
        for (i, helixNode) in helixNodes.enumerated() {
            if let name = helixNode.name, name == "basepair_\(relativeIndex)" {
                print("✅ Found base pair node at relative index \(relativeIndex) in helixNodes[\(i)]")
                addHighlightToNode(helixNode)
                found = true
                
                // Get the position from the first base child node (which has actual geometry position)
                var targetPosition = helixNode.worldPosition
                if let firstChild = helixNode.childNodes.first(where: { $0.name?.hasPrefix("base_") ?? false }) {
                    targetPosition = firstChild.worldPosition
                    print("🌍 Using base child world position: (\(targetPosition.x), \(targetPosition.y), \(targetPosition.z))")
                } else {
                    print("🌍 Using basepair world position: (\(targetPosition.x), \(targetPosition.y), \(targetPosition.z))")
                }
                
                focusCameraOn(position: targetPosition)
                break
            }
        }
        
        if !found {
            print("❌ Could not find basepair_\(relativeIndex)")
            print("❌ Available basepair nodes:")
            for (i, helixNode) in helixNodes.enumerated() {
                if let name = helixNode.name, name.hasPrefix("basepair_") {
                    print("     [\(i)] \(name)")
                }
            }
        }
    }
    
    private func addHighlightToNode(_ node: SCNNode) {
        // Add a glowing sphere around the selected base
        let highlightSphere = SCNSphere(radius: 1.5)
        highlightSphere.firstMaterial?.diffuse.contents = PlatformColor.yellow
        highlightSphere.firstMaterial?.transparency = 0.3
        highlightSphere.firstMaterial?.lightingModel = .constant
        
        let highlightNode = SCNNode(geometry: highlightSphere)
        highlightNode.name = "highlight"
        node.addChildNode(highlightNode)
        
        // Add pulsing animation
        let scaleUp = SCNAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.5)
        let pulse = SCNAction.sequence([scaleUp, scaleDown])
        let repeatPulse = SCNAction.repeatForever(pulse)
        highlightNode.runAction(repeatPulse)
        
        // Change label colors to red
        node.enumerateChildNodes { child, _ in
            if let name = child.name, name.hasPrefix("label_") {
                print("🔴 Changing label color: \(name)")
                if let textGeometry = child.childNodes.first?.geometry as? SCNText {
                    textGeometry.firstMaterial?.diffuse.contents = PlatformColor.red
                    textGeometry.firstMaterial?.emission.contents = PlatformColor.red
                }
            }
        }
    }
    
    func clearHighlights() {
        for helixNode in helixNodes {
            helixNode.enumerateChildNodes { node, _ in
                // Remove highlight spheres
                if node.name == "highlight" {
                    node.removeFromParentNode()
                }
                
                // Restore label colors to white
                if let name = node.name, name.hasPrefix("label_") {
                    print("⚪ Restoring label color: \(name)")
                    if let textGeometry = node.childNodes.first?.geometry as? SCNText {
                        textGeometry.firstMaterial?.diffuse.contents = PlatformColor.white
                        textGeometry.firstMaterial?.emission.contents = PlatformColor(white: 0.2, alpha: 1.0)
                    }
                }
            }
        }
    }
    
    private func focusCameraOn(position: SCNVector3) {
        print("📹 Focusing camera on position: (\(position.x), \(position.y), \(position.z))")
        
        // Stop any existing camera animations
        cameraNode.removeAllActions()
        
        // Calculate optimal camera position
        let cameraDistance: Float = 20.0
        
        // Position camera directly in front and slightly above the selected base
        let cameraPosition = SCNVector3(
            x: position.x,
            y: position.y + 5.0,  // Above
            z: position.z + cameraDistance  // In front
        )
        
        print("📹 Moving camera to: (\(cameraPosition.x), \(cameraPosition.y), \(cameraPosition.z))")
        
        // Use SCNTransaction for smooth animation with forced update
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Set camera position directly (bypasses SceneKit's camera control)
        cameraNode.position = cameraPosition
        cameraNode.look(at: position)
        
        SCNTransaction.commit()
        
        print("✅ Camera animation committed")
    }
}

// MARK: - Color Utilities

extension DNASceneManager {
    static func colorForBase(_ base: Character, scheme: DNAColorScheme, gcContent: Double = 0) -> PlatformColor {
        switch scheme {
        case .byBase:
            switch base {
            case "A": return PlatformColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0) // Orange
            case "T": return PlatformColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0) // Green
            case "G": return PlatformColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // Red
            case "C": return PlatformColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) // Yellow
            default: return .gray
            }
        case .byStrand:
            return .systemOrange
        case .uniform:
            return .systemGray
        case .gcContent:
            // Color based on GC content: low (blue) to high (red)
            let hue = 0.6 - (gcContent / 100.0) * 0.6 // 0.6 (blue) to 0.0 (red)
            return PlatformColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1.0)
        }
    }
}

