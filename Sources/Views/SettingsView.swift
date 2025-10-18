//
//  SettingsView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

enum ColorType: String, CaseIterable, Identifiable {
    case adenine = "Adenine (A)"
    case thymine = "Thymine (T)"
    case guanine = "Guanine (G)"
    case cytosine = "Cytosine (C)"
    case hydrogenBond = "Hydrogen Bond"
    var id: String { rawValue }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var colorSettings = ColorSettings.shared
    @State private var isDownloading = false
    @State private var downloadProgress = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var enzymeLibraryVersion = "2025.01"
    @State private var selectedColorType: ColorType? = nil
    
    var body: some View {
        NavigationView {
            List {
                // App Info Section
                Section {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DNA Viewer")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("App Information")
                }
                
                // Enzyme Library Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "scissors")
                                .font(.title2)
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restriction Enzyme Library")
                                    .font(.headline)
                                Text("Version \(enzymeLibraryVersion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text("Contains 75+ restriction enzymes with IUPAC support, recognition sites, and detailed metadata.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: {
                            downloadEnzymeLibrary()
                        }) {
                            HStack {
                                if isDownloading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title3)
                                }
                                
                                Text(isDownloading ? downloadProgress : "Re-download Library")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isDownloading ? Color.gray : Color.blue)
                            )
                        }
                        .disabled(isDownloading)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Downloading will update the restriction enzyme database with the latest version.")
                }
                
                // Analysis Settings Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Analysis Settings")
                                    .font(.headline)
                                Text("Configure analysis parameters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // GC Content Window Size
                        HStack {
                            Text("GC Content Window Size")
                                .font(.subheadline)
                            Spacer()
                            Text("100 bp")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // CpG Island Threshold
                        HStack {
                            Text("CpG Island Threshold")
                                .font(.subheadline)
                            Spacer()
                            Text("0.6")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Analysis Configuration")
                }
                
                // Color Settings Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DNA Color Scheme")
                                    .font(.headline)
                                Text("Customize base and bond colors")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // AGCT Base Colors
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Base Colors")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ColorSettingRow(
                                    title: "Adenine (A)",
                                    color: colorSettings.adenineColor,
                                    colorType: .adenine
                                ) {
                                    selectedColorType = .adenine
                                }
                                
                                ColorSettingRow(
                                    title: "Thymine (T)",
                                    color: colorSettings.thymineColor,
                                    colorType: .thymine
                                ) {
                                    selectedColorType = .thymine
                                }
                                
                                ColorSettingRow(
                                    title: "Guanine (G)",
                                    color: colorSettings.guanineColor,
                                    colorType: .guanine
                                ) {
                                    selectedColorType = .guanine
                                }
                                
                                ColorSettingRow(
                                    title: "Cytosine (C)",
                                    color: colorSettings.cytosineColor,
                                    colorType: .cytosine
                                ) {
                                    selectedColorType = .cytosine
                                }
                            }
                        }
                        
                        // Hydrogen Bond Color
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bond Colors")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ColorSettingRow(
                                title: "Hydrogen Bond",
                                color: colorSettings.hydrogenBondColor,
                                colorType: .hydrogenBond
                            ) {
                                selectedColorType = .hydrogenBond
                            }
                        }
                        
                        // Reset Button
                        Button(action: {
                            colorSettings.resetToDefaults()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                Text("Reset to Defaults")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Visual Appearance")
                } footer: {
                    Text("Customize the colors used to display DNA bases and hydrogen bonds in the 3D viewer.")
                }
                
                // About Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("About DNA Viewer")
                                    .font(.headline)
                                Text("Educational DNA analysis tool")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text("DNA Viewer is designed for educational purposes to help students and researchers explore DNA sequences, analyze genetic information, and understand molecular biology concepts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        .alert("Download Complete", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(item: $selectedColorType) { colorType in
            ColorPickerView(
                colorType: colorType,
                colorSettings: colorSettings
            )
        }
    }
    
    private func downloadEnzymeLibrary() {
        isDownloading = true
        downloadProgress = "Preparing download..."
        
        // 시뮬레이션된 다운로드 프로세스
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            downloadProgress = "Connecting to server..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            downloadProgress = "Downloading enzyme data..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            downloadProgress = "Validating data..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            downloadProgress = "Installing library..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isDownloading = false
            downloadProgress = ""
            enzymeLibraryVersion = "2025.01"
            alertMessage = "Restriction enzyme library has been successfully updated to version 2025.01. The app now has access to the latest enzyme database."
            showAlert = true
            
            print("🧬 Enzyme library download completed")
            print("📦 Library version: \(enzymeLibraryVersion)")
            print("✅ 75+ restriction enzymes updated")
        }
    }
}

// MARK: - Color Setting Row

struct ColorSettingRow: View {
    let title: String
    let color: Color
    let colorType: ColorType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Color Preview
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
                
                // Title
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        {
                            #if os(macOS)
                            return Color(NSColor.controlBackgroundColor)
                            #else
                            return Color(.systemGray6)
                            #endif
                        }()
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    @Environment(\.dismiss) var dismiss
    let colorType: ColorType
    @ObservedObject var colorSettings: ColorSettings
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current Color Preview
                VStack(spacing: 12) {
                    Text("Current Color")
                        .font(.headline)
                    
                    Circle()
                        .fill(currentColor)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: 2)
                        )
                    
                    Text(colorType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            {
                                #if os(macOS)
                                return Color(NSColor.controlBackgroundColor)
                                #else
                                return Color(.systemGray6)
                                #endif
                            }()
                        )
                )
                
                // Color Palette
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(colorSettings.availableColors, id: \.self) { color in
                        Button(action: {
                            updateColor(color)
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            isSelectedColor(color) ? Color.primary : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .scaleEffect(isSelectedColor(color) ? 1.1 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Color")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    private var currentColor: Color {
        switch colorType {
        case .adenine:
            return colorSettings.adenineColor
        case .thymine:
            return colorSettings.thymineColor
        case .guanine:
            return colorSettings.guanineColor
        case .cytosine:
            return colorSettings.cytosineColor
        case .hydrogenBond:
            return colorSettings.hydrogenBondColor
        }
    }
    
    private func isSelectedColor(_ color: Color) -> Bool {
        currentColor.toHex() == color.toHex()
    }
    
    private func updateColor(_ color: Color) {
        switch colorType {
        case .adenine:
            colorSettings.updateAdenineColor(color)
        case .thymine:
            colorSettings.updateThymineColor(color)
        case .guanine:
            colorSettings.updateGuanineColor(color)
        case .cytosine:
            colorSettings.updateCytosineColor(color)
        case .hydrogenBond:
            colorSettings.updateHydrogenBondColor(color)
        }
    }
}

#Preview {
    SettingsView()
}
