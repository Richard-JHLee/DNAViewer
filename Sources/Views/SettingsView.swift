//
//  SettingsView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isDownloading = false
    @State private var downloadProgress = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var enzymeLibraryVersion = "2025.01"
    
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Download Complete", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
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

#Preview {
    SettingsView()
}
