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
    
    private let turnAngle: Double = 0.28  // 나선 회전 각 (이미지 느낌에 맞게 약간 증가)
    
    // 화면 높이 기반 동적 간격 계산 (개선된 스케일링)
    private func calculateOptimalSpacing(sequenceLength: Int, screenHeight: Double) -> Double {
        let availableHeight = screenHeight * 0.9  // 90% 사용 (더 넓은 활용)
        let spacing = availableHeight / Double(sequenceLength)
        
        // 최소/최대 간격 제한 (더 넓은 범위)
        let minSpacing = 1.0
        let maxSpacing = 3.5
        
        let optimalSpacing = max(min(spacing, maxSpacing), minSpacing)
        
        print("🔍 LadderBuilder spacing: sequenceLength=\(sequenceLength), screenHeight=\(screenHeight), optimalSpacing=\(optimalSpacing)")
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
    
    // 중앙 정렬을 위한 수직 오프셋 계산
    private func calculateVerticalOffset(totalModelHeight: Double, screenHeight: Double) -> Double {
        let availableHeight = screenHeight * 0.85  // 사용 가능한 높이
        let margin = (availableHeight - totalModelHeight) / 2  // 상하 여백
        
        // 여백이 너무 작으면 모델을 위로 이동 (상단 UI 공간 확보)
        if margin < 50 {
            return -20.0  // 위로 약간 이동
        }
        
        return 0.0  // 중앙 정렬
    }
    
    func buildLadder(sequence: String, colorScheme: DNAColorScheme, startPosition: Int) -> [SCNNode] {
        // 메인 컨테이너 (회전은 이 노드에만 적용)
        let mainContainer = SCNNode()
        mainContainer.name = "ladderContainer"

        // 화면 기반 간격 계산
        let screenHeight = getScreenHeight()
        let spacing = calculateOptimalSpacing(sequenceLength: sequence.count, screenHeight: screenHeight)

        // 총 높이와 중앙 정렬 오프셋
        let totalModelHeight = Double(max(sequence.count - 1, 1)) * spacing
        let verticalOffset = calculateVerticalOffset(totalModelHeight: totalModelHeight, screenHeight: screenHeight)

        print("🔍 LadderBuilder margins: totalModelHeight=\(totalModelHeight), verticalOffset=\(verticalOffset)")

        // 스타일 파라미터 (이미지 유사)
        let backboneOffset: Double = 7.0            // 좌/우 중심 오프셋
        let backboneRadius: CGFloat = 0.9           // 두꺼운 파란 백본 두께
        let rungThickness: CGFloat = 0.45           // 색 막대 두께 (수평 바 높이)
        let hydrogenGap: Double = 0.8               // 중앙 흰색 결합 길이

        // 곡선 백본 생성
        let leftBackbone = createBackboneCurve(isLeft: true,
                                               count: sequence.count,
                                               spacing: spacing,
                                               offset: backboneOffset,
                                               turnAngle: turnAngle,
                                               thickness: backboneRadius,
                                               totalModelHeight: totalModelHeight,
                                               verticalOffset: verticalOffset)
        let rightBackbone = createBackboneCurve(isLeft: false,
                                                count: sequence.count,
                                                spacing: spacing,
                                                offset: backboneOffset,
                                                turnAngle: turnAngle,
                                                thickness: backboneRadius,
                                                totalModelHeight: totalModelHeight,
                                                verticalOffset: verticalOffset)
        mainContainer.addChildNode(leftBackbone)
        mainContainer.addChildNode(rightBackbone)

        // 각 위치의 색 막대 + 중앙 수소결합
        for i in 0..<sequence.count {
            let angle = Double(i) * turnAngle
            let y = Double(i) * spacing - totalModelHeight / 2 + verticalOffset

            // 나선에 따른 좌/우 X 위치
            let xLeft = -backboneOffset * cos(angle)
            let xRight = backboneOffset * cos(angle)

            let base = sequence[sequence.index(sequence.startIndex, offsetBy: i)]
            let comp = getComplementaryBase(base)

            let rungNode = createRung(y: y,
                                      xLeft: xLeft,
                                      xRight: xRight,
                                      backboneRadius: backboneRadius,
                                      hydrogenGap: hydrogenGap,
                                      rungThickness: rungThickness,
                                      base: base,
                                      complementaryBase: comp)
            mainContainer.addChildNode(rungNode)
        }

        // 컨테이너 초기 회전값
        mainContainer.eulerAngles = SCNVector3(0, 0, 0)
        return [mainContainer]
    }
    
    // 곡선 백본을 캡슐 세그먼트로 생성
    private func createBackboneCurve(isLeft: Bool,
                                     count: Int,
                                     spacing: Double,
                                     offset: Double,
                                     turnAngle: Double,
                                     thickness: CGFloat,
                                     totalModelHeight: Double,
                                     verticalOffset: Double) -> SCNNode {
        let container = SCNNode()
        let color = PlatformColor(red: 0.03, green: 0.29, blue: 0.60, alpha: 1.0)

        func point(_ idx: Int) -> SCNVector3 {
            let ang = Double(idx) * turnAngle
            let x = (isLeft ? -offset : offset) * cos(ang)
            let y = Double(idx) * spacing - totalModelHeight / 2 + verticalOffset
            return SCNVector3(Float(x), Float(y), 0)
        }

        if count < 2 { return container }
        for i in 0..<(count - 1) {
            let p1 = point(i)
            let p2 = point(i + 1)
            let seg = cylinderBetween(p1, p2, radius: thickness, color: color)
            container.addChildNode(seg)
        }
        return container
    }

    private func cylinderBetween(_ p1: SCNVector3, _ p2: SCNVector3, radius: CGFloat, color: PlatformColor) -> SCNNode {
        let v = SCNVector3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)
        let h = CGFloat(sqrt(Double(v.x*v.x + v.y*v.y + v.z*v.z)))
        let geom = SCNCapsule(capRadius: radius, height: h)
        geom.firstMaterial?.diffuse.contents = color
        geom.firstMaterial?.emission.contents = color
        let node = SCNNode(geometry: geom)
        node.position = SCNVector3((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5, (p1.z + p2.z) * 0.5)

        // y축 정렬 캡슐을 p1->p2 방향으로 회전
        let up = SCNVector3(0, 1, 0)
        let dir = normalize(v)
        let axis = cross(up, dir)
        let dotv = max(min(dot(up, dir), 1), -1)
        let angle = acos(dotv)
        node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        return node
    }
    
    private func normalize(_ v: SCNVector3) -> SCNVector3 {
        let l = sqrt(Double(v.x*v.x + v.y*v.y + v.z*v.z))
        if l == 0 { return SCNVector3(0, 1, 0) }
        return SCNVector3(Float(Double(v.x)/l), Float(Double(v.y)/l), Float(Double(v.z)/l))
    }

    private func cross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)
    }

    private func dot(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        return a.x*b.x + a.y*b.y + a.z*b.z
    }
    
    // 나선을 따라 놓이는 색 막대 + 중앙 수소결합
    private func createRung(y: Double,
                            xLeft: Double,
                            xRight: Double,
                            backboneRadius: CGFloat,
                            hydrogenGap: Double,
                            rungThickness: CGFloat,
                            base: Character,
                            complementaryBase: Character) -> SCNNode {
        let container = SCNNode()
        container.position = SCNVector3(0, Float(y), 0)

        // 백본 내측 엣지
        let leftInner = xLeft + Double(backboneRadius)
        let rightInner = xRight - Double(backboneRadius)

        // 중앙 흰색 결합 간격
        let gapL = -hydrogenGap * 0.5
        let gapR = hydrogenGap * 0.5

        // 좌/우 색 막대 폭과 중심 계산
        let leftWidth = max(gapL - leftInner, 0.12)
        let leftCenter = (leftInner + gapL) * 0.5

        let rightWidth = max(rightInner - gapR, 0.12)
        let rightCenter = (gapR + rightInner) * 0.5

        // 좌측 색 막대
        let leftBox = SCNBox(width: CGFloat(leftWidth), height: rungThickness, length: 0.02, chamferRadius: rungThickness * 0.25)
        leftBox.firstMaterial?.diffuse.contents = getBaseColor(base)
        let leftNode = SCNNode(geometry: leftBox)
        leftNode.position = SCNVector3(Float(leftCenter), 0, 0)
        container.addChildNode(leftNode)

        // 우측 색 막대
        let rightBox = SCNBox(width: CGFloat(rightWidth), height: rungThickness, length: 0.02, chamferRadius: rungThickness * 0.25)
        rightBox.firstMaterial?.diffuse.contents = getBaseColor(complementaryBase)
        let rightNode = SCNNode(geometry: rightBox)
        rightNode.position = SCNVector3(Float(rightCenter), 0, 0)
        container.addChildNode(rightNode)

        // 중앙 수소결합 (밝은 흰색)
        let bond = SCNBox(width: CGFloat(hydrogenGap), height: rungThickness * 0.28, length: 0.008, chamferRadius: rungThickness * 0.14)
        bond.firstMaterial?.diffuse.contents = PlatformColor.white
        bond.firstMaterial?.emission.contents = PlatformColor(white: 1.0, alpha: 1.0)
        let bondNode = SCNNode(geometry: bond)
        container.addChildNode(bondNode)

        return container
    }
    
    // Get color for base (flat 2D style palette)
    private func getBaseColor(_ base: Character) -> PlatformColor {
        switch base {
        case "A": return PlatformColor(red: 0.95, green: 0.28, blue: 0.28, alpha: 1.0) // Red
        case "T": return PlatformColor(red: 0.98, green: 0.80, blue: 0.20, alpha: 1.0) // Yellow
        case "G": return PlatformColor(red: 0.26, green: 0.78, blue: 0.62, alpha: 1.0) // Teal-Green
        case "C": return PlatformColor(red: 0.03, green: 0.29, blue: 0.60, alpha: 1.0) // Deep Blue
        default: return PlatformColor.lightGray
        }
    }
    
    private func createStrandNode(base: Character, position: SCNVector3, colorScheme: DNAColorScheme, index: Int, totalLength: Int, isLeft: Bool) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.position = position
        
        // Create backbone element (sugar-phosphate)
        let backbone = SCNSphere(radius: 0.25)
        backbone.firstMaterial?.diffuse.contents = PlatformColor.systemBlue
        backbone.firstMaterial?.specular.contents = PlatformColor.white
        
        let backboneNode = SCNNode(geometry: backbone)
        containerNode.addChildNode(backboneNode)
        
        // Create base (smaller sphere for better separation)
        let baseSphere = SCNSphere(radius: 0.4)
        let color = DNASceneManager.colorForBase(base, scheme: colorScheme, position: index, totalLength: totalLength)
        baseSphere.firstMaterial?.diffuse.contents = color
        baseSphere.firstMaterial?.specular.contents = PlatformColor.white
        baseSphere.firstMaterial?.emission.contents = PlatformColor(white: 0.3, alpha: 1.0)
        
        let baseNode = SCNNode(geometry: baseSphere)
        // Position base in front of backbone (toward center) - 더 멀리 배치하여 명확한 분리
        baseNode.position = SCNVector3(isLeft ? 2.0 : -2.0, 0, 0)
        containerNode.addChildNode(baseNode)
        
        // Add large, clear text label with enhanced visibility
        let textGeometry = SCNText(string: String(base), extrusionDepth: 0.4)
        #if os(macOS)
        textGeometry.font = NSFont.systemFont(ofSize: 4.0, weight: .bold)
        #else
        textGeometry.font = UIFont.systemFont(ofSize: 4.0, weight: .bold)
        #endif
        textGeometry.flatness = 0.01
        textGeometry.firstMaterial?.diffuse.contents = PlatformColor.white
        textGeometry.firstMaterial?.emission.contents = PlatformColor(white: 2.0, alpha: 1.0)
        textGeometry.firstMaterial?.specular.contents = PlatformColor.black
        textGeometry.firstMaterial?.lightingModel = .constant
        textGeometry.firstMaterial?.isDoubleSided = true
        
        let textNode = SCNNode(geometry: textGeometry)
        let (min, max) = textGeometry.boundingBox
        let textWidth = max.x - min.x
        let textHeight = max.y - min.y
        textNode.position = SCNVector3(-textWidth / 2, -textHeight / 2, 2.0)
        textNode.scale = SCNVector3(1.0, 1.0, 1.0)
        textNode.renderingOrder = 99999
        
        containerNode.addChildNode(textNode)
        
        return containerNode
    }
    
    private func createBasePairBond(leftPos: SCNVector3, rightPos: SCNVector3) -> SCNNode {
        // Calculate bond length and direction
        let bondLength = sqrt(pow(rightPos.x - leftPos.x, 2) + pow(rightPos.y - leftPos.y, 2))
        let bondAngle = atan2(rightPos.y - leftPos.y, rightPos.x - leftPos.x)
        
        // Create enhanced bond geometry with better visibility
        let bond = SCNBox(width: CGFloat(bondLength), height: 0.1, length: 0.1, chamferRadius: 0.05)
        bond.firstMaterial?.diffuse.contents = PlatformColor.white
        bond.firstMaterial?.specular.contents = PlatformColor.white
        bond.firstMaterial?.emission.contents = PlatformColor(white: 2.0, alpha: 1.0)
        
        let bondNode = SCNNode(geometry: bond)
        
        // Position and rotate bond to connect the two bases
        let midX = (leftPos.x + rightPos.x) / 2
        let midY = (leftPos.y + rightPos.y) / 2
        bondNode.position = SCNVector3(midX, midY, 0)
        bondNode.rotation = SCNVector4(0, 0, 1, Double(bondAngle))
        
        return bondNode
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