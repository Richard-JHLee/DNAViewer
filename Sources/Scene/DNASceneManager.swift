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
    @Published var colorSettings = ColorSettings.shared
    
    // Track highlighted cut sites for camera focusing
    @Published var highlightedCutSites: [Int] = []
    
    // Flag to prevent concurrent rebuilds
    private var isRebuilding = false
    
    var scene: SCNScene
    private var cameraNode: SCNNode
    private var helixNodes: [SCNNode] = []
    private var currentSequence: DNASequence?
    
    // Display settings
    var displayStart: Int = 0
    var displayLength: Int = 100 // Show only subset for performance
    var currentGroup: Int = 1
    var totalGroups: Int = 1
    var groupSize: Int = 100  // Increased for better visualization
    
    // 실제 표시되는 염기서열 수 (안전장치 적용 후)
    var actualDisplayLength: Int {
        guard let sequence = currentSequence else { return displayLength }
        // 모든 시퀀스에 대해 100개 표시 (제한 제거)
        let maxDisplayLength = 100
        let safeLength = min(displayLength, maxDisplayLength)
        print("🔍 actualDisplayLength: displayLength=\(displayLength), maxDisplayLength=\(maxDisplayLength), safeLength=\(safeLength)")
        return safeLength
    }
    
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
        cameraNode.camera?.fieldOfView = 60  // Wider field of view to see more
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 1000
        cameraNode.position = SCNVector3(x: 0, y: 3, z: 25)  // Further back to see entire DNA
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))    // Look straight at the center
        
        // Add constraint to lock X position
        let xConstraint = SCNTransformConstraint(inWorldSpace: true) { (node, transform) -> SCNMatrix4 in
            var newTransform = transform
            // Keep X position at 0
            newTransform.m41 = 0
            return newTransform
        }
        cameraNode.constraints = [xConstraint]
        
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
        print("🔄 loadSequence called: \(sequence.name)")
        
        // 이전 상태 완전 초기화
        highlightedCutSites = []
        selectedRange = nil
        selectedBaseIndex = nil
        
        // 표시 범위 초기화 (중요!)
        displayStart = 0
        currentGroup = 1
        
        currentSequence = sequence
        
        // Calculate groups based on sequence ID and length
        calculateGroups(for: sequence)
        
        // UI 업데이트 강제
        objectWillChange.send()
        
        rebuildScene()
        
        print("✅ loadSequence completed: totalGroups=\(totalGroups), currentGroup=\(currentGroup), displayStart=\(displayStart), displayLength=\(displayLength)")
    }
    
    private func calculateGroups(for sequence: DNASequence) {
        let sequenceId = sequence.name.lowercased()
        
        print("🔍 Calculating groups for sequence: '\(sequence.name)' (lowercased: '\(sequenceId)')")
        print("🔍 Sequence length: \(sequence.length)")
        
        // 모든 시퀀스에 대해 일관된 그룹 크기 설정
        groupSize = 100  // 모든 시퀀스를 100개씩 표시
        print("✅ Setting groupSize to 100 for consistent display")
        
        // 그룹 수 계산 (첫 번째 그룹으로 초기화)
        if sequence.length <= groupSize {
            totalGroups = 1
            currentGroup = 1
            displayStart = 0
            displayLength = sequence.length
            print("📊 Single group: displayStart=\(displayStart), displayLength=\(displayLength)")
        } else {
            totalGroups = (sequence.length + groupSize - 1) / groupSize  // 올림 계산
            currentGroup = 1  // 항상 첫 번째 그룹부터 시작
            displayStart = 0  // 첫 번째 그룹은 0부터 시작
            displayLength = min(groupSize, sequence.length)
            print("📊 Multiple groups (\(totalGroups)): displayStart=\(displayStart), displayLength=\(displayLength)")
        }
        
        // 안전장치 적용 (APOE는 200개, 다른 시퀀스는 20개로 제한)
        let isAPOE = sequenceId.contains("apoe")
        let maxDisplayLength = isAPOE ? 200 : 20
        let safeDisplayLength = min(displayLength, maxDisplayLength)
        if safeDisplayLength < displayLength {
            print("⚠️ calculateGroups: Limiting display from \(displayLength) to \(safeDisplayLength) for stability")
            displayLength = safeDisplayLength
        }
        
        print("🧬 \(sequence.name): \(sequence.length) bases -> \(totalGroups) groups (size: \(groupSize))")
        print("🧬 Final values: currentGroup=\(currentGroup), displayStart=\(displayStart), displayLength=\(displayLength)")
        
        // UI 업데이트를 강제하여 SequenceBar가 새로운 값을 반영하도록 함
        objectWillChange.send()
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
        
        // Calculate start/length with safety checks
        let newStart = (group - 1) * self.groupSize
        guard newStart < sequence.length else {
            print("❌ loadGroup: start \(newStart) >= sequence length \(sequence.length)")
            return
        }
        
        let newLength = min(self.groupSize, sequence.length - newStart)
        guard newLength > 0 else {
            print("❌ loadGroup: computed length <= 0")
            return
        }
        
        // UI 업데이트를 명시적으로 트리거
        objectWillChange.send()
        
        // 즉시 currentGroup 업데이트 (UI가 바로 반응하도록)
        self.currentGroup = group
        self.displayStart = newStart
        self.displayLength = newLength
        
        // 안전장치 적용 (모든 시퀀스를 100개로 통일)
        let maxDisplayLength = 100
        let safeDisplayLength = min(self.displayLength, maxDisplayLength)
        if safeDisplayLength < self.displayLength {
            print("⚠️ loadGroup: Limiting display from \(self.displayLength) to \(safeDisplayLength) for stability")
            self.displayLength = safeDisplayLength
        }
        
        print("📊 Group \(group): start=\(self.displayStart), length=\(self.displayLength)")
        print("✅ currentGroup updated to: \(self.currentGroup)")
        
        // Scene 재구성은 비동기로 (메인 스레드에서만)
        if Thread.isMainThread {
            rebuildScene()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.rebuildScene()
            }
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
        // Prevent concurrent rebuilds to avoid infinite recursion
        guard !isRebuilding else {
            print("⚠️ Rebuild already in progress, skipping...")
            return
        }
        
        isRebuilding = true
        
        // Clear existing nodes first to free memory
        // Save cut sites before clearing
        let savedCutSites = highlightedCutSites
        print("🧹 Clearing \(helixNodes.count) existing nodes...")
        print("💾 Saved \(savedCutSites.count) cut sites for re-application")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.helixNodes.forEach { $0.removeFromParentNode() }
            self.helixNodes.removeAll()
            
            // Restore cut sites
            self.highlightedCutSites = savedCutSites
            
            // Force memory cleanup
            autoreleasepool {
                // This will help release memory immediately
            }
            
            guard let sequence = self.currentSequence else { 
                self.isRebuilding = false
                return 
            }
            
            // Limit display length for large sequences to prevent crash
            let maxDisplayLength = 100  // 모든 시퀀스에 대해 100개로 통일
            let safeDisplayLength = min(self.displayLength, maxDisplayLength)
            if safeDisplayLength < self.displayLength {
                print("⚠️ Limiting display from \(self.displayLength) to \(safeDisplayLength) for stability")
                self.displayLength = safeDisplayLength
            }
            
            // Build according to current representation on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var newNodes: [SCNNode] = []
                
                switch self.currentRepresentation {
                case .doubleHelix:
                    newNodes = self.buildDoubleHelixNodes(sequence: sequence)
                case .ladder:
                    newNodes = self.buildLadderNodes(sequence: sequence)
                case .ballAndStick:
                    newNodes = self.buildBallAndStickNodes(sequence: sequence)
                case .sequenceOnly:
                    break
                }
                
                // Add nodes on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    print("➕ Adding \(newNodes.count) new nodes to scene...")
                    for node in newNodes {
                        self.scene.rootNode.addChildNode(node)
                        self.helixNodes.append(node)
                    }
                    print("✅ Scene rebuild complete. Total nodes: \(self.helixNodes.count)")
                    
                    // Reset the rebuilding flag
                    self.isRebuilding = false
                    
                    // Re-apply highlights if there are cut sites
                    if !self.highlightedCutSites.isEmpty {
                        print("🔄 Re-applying highlights for \(self.highlightedCutSites.count) cut sites after rebuild")
                        // Small delay to ensure nodes are fully rendered
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.highlightPositionsInCurrentGroup(self.highlightedCutSites)
                        }
                    }
                }
            }
        }
    }
    
    // Background-safe node builders (return nodes without adding to scene)
    private func buildDoubleHelixNodes(sequence: DNASequence) -> [SCNNode] {
        let helixBuilder = HelixBuilder()
        let displaySeq = getDisplaySequence(sequence)
        
        guard !displaySeq.isEmpty else {
            print("⚠️ buildDoubleHelixNodes: empty display sequence")
            return []
        }
        
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
        return nodes
    }
    
    private func buildLadderNodes(sequence: DNASequence) -> [SCNNode] {
        let ladderBuilder = LadderBuilder()
        let displaySeq = getDisplaySequence(sequence)
        
        guard !displaySeq.isEmpty else { return [] }
        
        return ladderBuilder.buildLadder(
            sequence: displaySeq,
            colorScheme: colorScheme,
            startPosition: displayStart
        )
    }
    
    private func buildBallAndStickNodes(sequence: DNASequence) -> [SCNNode] {
        let ballStickBuilder = BallStickBuilder()
        let displaySeq = getDisplaySequence(sequence)
        
        guard !displaySeq.isEmpty else { return [] }
        
        return ballStickBuilder.buildBallStick(
            sequence: displaySeq,
            colorScheme: colorScheme,
            startPosition: displayStart
        )
    }
    
    // Deprecated: kept for compatibility, use buildXXXNodes instead
    func buildDoubleHelix(sequence: DNASequence) {
        let nodes = buildDoubleHelixNodes(sequence: sequence)
        for node in nodes {
            scene.rootNode.addChildNode(node)
            helixNodes.append(node)
        }
    }
    
    func buildLadder(sequence: DNASequence) {
        let nodes = buildLadderNodes(sequence: sequence)
        for node in nodes {
            scene.rootNode.addChildNode(node)
            helixNodes.append(node)
        }
    }
    
    func buildBallAndStick(sequence: DNASequence) {
        let nodes = buildBallAndStickNodes(sequence: sequence)
        for node in nodes {
            scene.rootNode.addChildNode(node)
            helixNodes.append(node)
        }
    }
    
    private func getDisplaySequence(_ sequence: DNASequence) -> String {
        let start = min(displayStart, sequence.length)
        let end = min(displayStart + displayLength, sequence.length)
        
        guard start < sequence.sequence.count, end <= sequence.sequence.count, start < end else {
            print("❌ getDisplaySequence: Invalid range start=\(start) end=\(end) seqLen=\(sequence.sequence.count)")
            return ""
        }
        
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
            // Y-axis rotation (rotate around vertical axis)
            let rotation = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 8)
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
        print("🔄 Resetting view to default state...")
        
        // Stop any animations
        for node in helixNodes {
            node.removeAction(forKey: "rotation")
        }
        isAnimating = false
        
        // Clear restriction enzyme cut site highlights
        clearHighlights()
        print("   ✅ Cleared all restriction enzyme highlights")
        
        // Reset camera position
        cameraNode.position = SCNVector3(x: 0, y: 3, z: 25)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        
        // Reset DNA model rotation
        for node in helixNodes {
            node.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
        }
        
        print("✅ View reset complete")
    }
    
    // MARK: - Gesture Handlers
    
    private var lastRotationY: CGFloat = 0
    
    func handleDrag(translation: CGSize) {
        // Only allow Y-axis rotation (left/right drag)
        let rotationSpeed: CGFloat = 0.01
        let rotationY = Float(translation.width * rotationSpeed)
        
        // Apply rotation to all DNA nodes around Y-axis only
        for node in helixNodes {
            node.eulerAngles.y = rotationY
        }
    }
    
    func handleZoom(scale: CGFloat) {
        // Adjust camera Z position for zoom
        let minZ: Float = 10
        let maxZ: Float = 50
        let newZ = Float(25.0 / scale) // Base position 25
        
        cameraNode.position.z = min(max(newZ, minZ), maxZ)
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
    
    // MARK: - Restriction Enzyme Visualization
    
    /// Highlight multiple positions (e.g., restriction enzyme cut sites)
    func highlightPositions(_ positions: [Int]) {
        clearHighlights()
        
        // Store the cut sites for camera focusing
        highlightedCutSites = positions.sorted()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✂️ Highlighting \(positions.count) cut sites")
        print("📍 Positions: \(highlightedCutSites)")
        
        guard !highlightedCutSites.isEmpty else {
            print("⚠️ No cut sites to highlight")
            return
        }
        
        // Calculate which groups contain cut sites
        var groupsWithCutSites: [Int: [Int]] = [:]  // group -> positions in that group
        for position in highlightedCutSites {
            let group = (position / groupSize) + 1
            if groupsWithCutSites[group] == nil {
                groupsWithCutSites[group] = []
            }
            groupsWithCutSites[group]?.append(position)
        }
        
        let affectedGroups = groupsWithCutSites.keys.sorted()
        print("📊 Cut sites span \(affectedGroups.count) groups: \(affectedGroups)")
        
        // Navigate to the first group with cut sites
        let firstGroup = affectedGroups.first ?? currentGroup
        print("🎯 Navigating to first group with cut sites: G\(firstGroup)")
        
        if firstGroup != currentGroup {
            print("🔄 Loading group \(firstGroup)...")
            loadGroup(firstGroup)
            
            // Highlight positions after group load completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🎨 Highlighting positions in group \(firstGroup)")
                self.highlightPositionsInCurrentGroup(self.highlightedCutSites)
            }
        } else {
            print("✅ Already in target group - highlighting immediately")
            highlightPositionsInCurrentGroup(highlightedCutSites)
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Highlight positions within the current display group
    private func highlightPositionsInCurrentGroup(_ positions: [Int]) {
        print("🎨 highlightPositionsInCurrentGroup called")
        print("   Positions to highlight: \(positions)")
        print("   Display range: \(displayStart) - \(displayStart + displayLength)")
        print("   Available helixNodes: \(helixNodes.count)")
        
        var highlightCount = 0
        
        for position in positions {
            let relativeIndex = position - displayStart
            
            guard relativeIndex >= 0 && relativeIndex < displayLength else {
                print("   ⏭️ Position \(position) (relative: \(relativeIndex)) is out of current display range")
                continue
            }
            
            print("   🔍 Looking for node: basepair_\(relativeIndex) (global position: \(position))")
            
            // Find and highlight the node at this position
            var found = false
            for helixNode in helixNodes {
                if let name = helixNode.name, name == "basepair_\(relativeIndex)" {
                    print("   ✅ Found node: \(name)")
                    addCutSiteMarker(to: helixNode, at: position)
                    highlightCount += 1
                    found = true
                    break
                }
            }
            
            if !found {
                print("   ❌ Node not found for position \(position) (relative: \(relativeIndex))")
                // Debug: list first few node names
                let nodeNames = helixNodes.prefix(5).compactMap { $0.name }
                print("   📋 First few node names: \(nodeNames)")
            }
        }
        
        print("   📊 Highlighted \(highlightCount) out of \(positions.count) positions in current group")
    }
    
    /// Add a cut site marker (scissors icon) to a node
    private func addCutSiteMarker(to node: SCNNode, at position: Int) {
        print("✂️ Adding cut site marker at position \(position)")
        
        // Create a bright red cutting plane marker (larger and more visible)
        let cutPlane = SCNBox(width: 4.0, height: 0.2, length: 4.0, chamferRadius: 0.1)
        cutPlane.firstMaterial?.diffuse.contents = PlatformColor.red
        cutPlane.firstMaterial?.emission.contents = PlatformColor.red  // Make it glow
        cutPlane.firstMaterial?.transparency = 0.7
        cutPlane.firstMaterial?.lightingModel = .constant
        
        let cutMarker = SCNNode(geometry: cutPlane)
        cutMarker.name = "cut_site_\(position)"
        
        // Position the marker slightly offset for better visibility
        cutMarker.position = SCNVector3(0, 0, 0)
        node.addChildNode(cutMarker)
        
        // Add a sphere marker for extra visibility
        let sphere = SCNSphere(radius: 0.8)
        sphere.firstMaterial?.diffuse.contents = PlatformColor.yellow
        sphere.firstMaterial?.emission.contents = PlatformColor.yellow
        sphere.firstMaterial?.lightingModel = .constant
        sphere.firstMaterial?.transparency = 0.8
        
        let sphereMarker = SCNNode(geometry: sphere)
        sphereMarker.name = "cut_site_sphere_\(position)"
        sphereMarker.position = SCNVector3(0, 2.0, 0)  // Position above
        node.addChildNode(sphereMarker)
        
        // Add flashing animation to both markers
        let fadeOut = SCNAction.fadeOpacity(to: 0.3, duration: 0.4)
        let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: 0.4)
        let flash = SCNAction.sequence([fadeOut, fadeIn])
        let repeatFlash = SCNAction.repeatForever(flash)
        cutMarker.runAction(repeatFlash)
        sphereMarker.runAction(repeatFlash)
        
        // Add pulsing scale animation
        let scaleUp = SCNAction.scale(to: 1.2, duration: 0.4)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.4)
        let pulse = SCNAction.sequence([scaleUp, scaleDown])
        let repeatPulse = SCNAction.repeatForever(pulse)
        sphereMarker.runAction(repeatPulse)
        
        print("   ✅ Added plane and sphere markers")
        
        // Focus camera on the first cut site
        if position == (highlightedCutSites.first ?? -1) {
            print("   📹 This is the first cut site - focusing camera")
            focusCameraOn(position: node.worldPosition)
        }
    }
    
    func clearHighlights(preserveCutSites: Bool = false) {
        print("🧹 Clearing all highlights and cut site markers")
        
        // Clear tracked cut sites only if not preserving
        if !preserveCutSites {
            let previousCount = highlightedCutSites.count
            highlightedCutSites.removeAll()
            print("   Cleared \(previousCount) tracked cut sites")
        } else {
            print("   Preserving \(highlightedCutSites.count) tracked cut sites")
        }
        
        var removedCount = 0
        
        for helixNode in helixNodes {
            helixNode.enumerateChildNodes { node, _ in
                // Remove highlight spheres
                if node.name == "highlight" {
                    node.removeFromParentNode()
                    removedCount += 1
                }
                
                // Remove cut site plane markers
                if let name = node.name, name.hasPrefix("cut_site_") {
                    node.removeFromParentNode()
                    removedCount += 1
                }
                
                // Remove cut site sphere markers
                if let name = node.name, name.hasPrefix("cut_site_sphere_") {
                    node.removeFromParentNode()
                    removedCount += 1
                }
                
                // Restore label colors to white
                if let name = node.name, name.hasPrefix("label_") {
                    if let textGeometry = node.childNodes.first?.geometry as? SCNText {
                        textGeometry.firstMaterial?.diffuse.contents = PlatformColor.white
                        textGeometry.firstMaterial?.emission.contents = PlatformColor(white: 0.2, alpha: 1.0)
                    }
                }
            }
        }
        
        print("   Removed \(removedCount) marker nodes")
        print("✅ Highlights cleared")
    }
    
    private func focusCameraOn(position: SCNVector3) {
        print("📹 Focusing camera on position: (\(position.x), \(position.y), \(position.z))")
        
        // Stop any existing camera animations
        cameraNode.removeAllActions()
        
        // Calculate optimal camera position
        #if os(macOS)
        let cameraDistance: CGFloat = 20.0
        // Position camera directly in front and slightly above the selected base
        let cameraPosition = SCNVector3(
            x: CGFloat(position.x),
            y: CGFloat(position.y) + 5.0,  // Above
            z: CGFloat(position.z) + cameraDistance  // In front
        )
        #else
        let cameraDistance: Float = 20.0
        // Position camera directly in front and slightly above the selected base
        let cameraPosition = SCNVector3(
            x: position.x,
            y: position.y + 5.0,  // Above
            z: position.z + cameraDistance  // In front
        )
        #endif
        
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
    // Pre-defined platform colors to avoid any UIColor/NSColor init calls during rendering
    #if os(macOS)
    private static let defaultAdenine = NSColor.systemOrange
    private static let defaultThymine = NSColor.systemGreen
    private static let defaultGuanine = NSColor.systemRed
    private static let defaultCytosine = NSColor.systemYellow
    private static let defaultHydrogen = NSColor.white
    #else
    private static let defaultAdenine = UIColor.systemOrange
    private static let defaultThymine = UIColor.systemGreen
    private static let defaultGuanine = UIColor.systemRed
    private static let defaultCytosine = UIColor.systemYellow
    private static let defaultHydrogen = UIColor.white
    #endif

    static func colorForBase(_ base: Character, scheme: DNAColorScheme, gcContent: Double = 0) -> PlatformColor {
        switch scheme {
        case .byBase:
            switch base {
            case "A": return defaultAdenine
            case "T": return defaultThymine
            case "G": return defaultGuanine
            case "C": return defaultCytosine
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

extension DNASceneManager {
    static func hydrogenPlatformColor() -> PlatformColor {
        return defaultHydrogen
    }
}

// MARK: - PlatformColor Extension
extension PlatformColor {
    convenience init(_ color: Color) {
        #if os(macOS)
        if let cg = color.cgColor, let ns = NSColor(cgColor: cg) {
            self.init(srgbRed: ns.redComponent, green: ns.greenComponent, blue: ns.blueComponent, alpha: ns.alphaComponent)
        } else {
            self.init(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        }
        #else
        // Use direct CGColor access to avoid infinite recursion
        if let cgColor = color.cgColor {
            self.init(cgColor: cgColor)
        } else {
            self.init(cgColor: UIColor.white.cgColor)
        }
        #endif
    }
}
