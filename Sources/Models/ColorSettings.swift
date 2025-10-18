//
//  ColorSettings.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI
import Foundation

// MARK: - Color Settings Model

class ColorSettings: ObservableObject {
    static let shared = ColorSettings()
    
    // AGCT 염기 색상
    @Published var adenineColor: Color = .orange
    @Published var thymineColor: Color = .green
    @Published var guanineColor: Color = .red
    @Published var cytosineColor: Color = .yellow
    
    // 수소결합 색상
    @Published var hydrogenBondColor: Color = .white
    
    // 기본 색상 팔레트
    let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue,
        .indigo, .purple, .pink, .brown, .gray, .white, .black
    ]
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        // AGCT 색상 저장
        defaults.set(adenineColor.toHex(), forKey: "adenineColor")
        defaults.set(thymineColor.toHex(), forKey: "thymineColor")
        defaults.set(guanineColor.toHex(), forKey: "guanineColor")
        defaults.set(cytosineColor.toHex(), forKey: "cytosineColor")
        
        // 수소결합 색상 저장
        defaults.set(hydrogenBondColor.toHex(), forKey: "hydrogenBondColor")
        
        print("🎨 Color settings saved")
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // AGCT 색상 로드
        if let adenineHex = defaults.string(forKey: "adenineColor") {
            adenineColor = Color(hex: adenineHex)
        }
        if let thymineHex = defaults.string(forKey: "thymineColor") {
            thymineColor = Color(hex: thymineHex)
        }
        if let guanineHex = defaults.string(forKey: "guanineColor") {
            guanineColor = Color(hex: guanineHex)
        }
        if let cytosineHex = defaults.string(forKey: "cytosineColor") {
            cytosineColor = Color(hex: cytosineHex)
        }
        
        // 수소결합 색상 로드
        if let hydrogenHex = defaults.string(forKey: "hydrogenBondColor") {
            hydrogenBondColor = Color(hex: hydrogenHex)
        }
        
        print("🎨 Color settings loaded")
    }
    
    // MARK: - Color Updates
    
    func updateAdenineColor(_ color: Color) {
        adenineColor = color
        saveSettings()
    }
    
    func updateThymineColor(_ color: Color) {
        thymineColor = color
        saveSettings()
    }
    
    func updateGuanineColor(_ color: Color) {
        guanineColor = color
        saveSettings()
    }
    
    func updateCytosineColor(_ color: Color) {
        cytosineColor = color
        saveSettings()
    }
    
    func updateHydrogenBondColor(_ color: Color) {
        hydrogenBondColor = color
        saveSettings()
    }
    
    func resetToDefaults() {
        adenineColor = .orange
        thymineColor = .green
        guanineColor = .red
        cytosineColor = .yellow
        hydrogenBondColor = .white
        saveSettings()
    }
}

// MARK: - Color Extensions

extension Color {
    func toHex() -> String {
        var red: CGFloat = 1
        var green: CGFloat = 1
        var blue: CGFloat = 1
        var alpha: CGFloat = 1

        #if os(macOS)
        if let cg = self.cgColor, let ns = NSColor(cgColor: cg)?.usingColorSpace(.sRGB) {
            ns.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
        #else
        if let cg = self.cgColor {
            UIColor(cgColor: cg).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
        #endif

        let r = max(0, min(255, Int(round(red * 255))))
        let g = max(0, min(255, Int(round(green * 255))))
        let b = max(0, min(255, Int(round(blue * 255))))
        let rgb = (r << 16) | (g << 8) | b
        return String(format: "#%06x", rgb)
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
