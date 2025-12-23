//
//  ContentView.swift
//  noclap
//
//  Created by Richard Oliver Bray on 15/10/2025.
//

/*
 
 different rows, like bluetooth
 1. NoClap, on off toggle
 2. Devices,
 3. List of mics
 4. Delay slider (ms)
 5. About...
 */

import SwiftUI

struct ContentView: View {
    @StateObject private var deviceManager = DeviceManager()
    @State private var selectedTab: String = "General"
    @State private var isEnabled = false
    @State private var hoveredDevice: String?
    @State private var selectedDevice = "Macbook pro microphone"
    @State private var hoveredVirtualCable: String?
    @State private var selectedVirtualCable: String?
    @State private var delayValue: Double = 140
    
    private var indicatorText: String {
        isEnabled ? "on" : "off"
    }


    var body: some View {
        VStack(spacing: 0) {
            // Tab bar header with grey background
            VStack(spacing: 0) {
                // Title row
                HStack {
                    Text(selectedTab)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Tab buttons row
                HStack(spacing: 30) {
                    TabButton(
                        label: "General",
                        icon: "gearshape.fill",
                        isSelected: selectedTab == "General"
                    ) {
                        selectedTab = "General"
                    }
                    
                    TabButton(
                        label: "License",
                        icon: "doc.fill",
                        isSelected: selectedTab == "License"
                    ) {
                        selectedTab = "License"
                    }
                    
                    TabButton(
                        label: "About",
                        icon: "info.circle.fill",
                        isSelected: selectedTab == "About"
                    ) {
                        selectedTab = "About"
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Content
            Group {
                if selectedTab == "General" {
                    GeneralTab(isEnabled: $isEnabled, hoveredDevice: $hoveredDevice, selectedDevice: $selectedDevice, hoveredVirtualCable: $hoveredVirtualCable, selectedVirtualCable: $selectedVirtualCable, delayValue: $delayValue, deviceManager: deviceManager)
                } else if selectedTab == "License" {
                    LicenseTab()
                } else if selectedTab == "About" {
                    AboutTab()
                }
            }
            .padding()
        }
    }
}

struct TabButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(isSelected ? .blue : .gray)
        .buttonStyle(PlainButtonStyle())
    }
}

struct GeneralTab: View {
    @Binding var isEnabled: Bool
    @Binding var hoveredDevice: String?
    @Binding var selectedDevice: String
    @Binding var hoveredVirtualCable: String?
    @Binding var selectedVirtualCable: String?
    @Binding var delayValue: Double
    @ObservedObject var deviceManager: DeviceManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Summary section
                
                Text("Summary")
                    .opacity(0.6)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    if selectedDevice.isEmpty {
                        Text("Please select a device to get started")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    } else if selectedVirtualCable == nil {
                        Text("Device: \(selectedDevice)")
                            .fontWeight(.semibold)
                        Text("Output: Not selected")
                            .foregroundColor(.blue)
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Device: \(selectedDevice)")
                                    .fontWeight(.semibold)
                                Text("Output: \(selectedVirtualCable!)")
                                    .fontWeight(.semibold)
                                Text("Delay: \(Int(delayValue)) ms")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            Toggle("", isOn: $isEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .onChange(of: isEnabled) {
                                    if isEnabled && !selectedDevice.isEmpty && selectedVirtualCable != nil {
                                        deviceManager.startAudioProcessing(inputDevice: selectedDevice, outputDevice: selectedVirtualCable!, delayMs: delayValue)
                                    } else {
                                        deviceManager.stopAudioProcessing()
                                    }
                                }
                        }
                    }
                }
                
                Divider()
                
                Text("Devices")
                    .opacity(0.6)
                    .fontWeight(.bold)
                
                ForEach(deviceManager.devices, id: \.self) { device in
                    Button(action: {
                        selectedDevice = device
                    }) {
                        HStack {
                            Image(systemName: "microphone")
                            Text(device).fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                selectedDevice == device ? Color.blue.opacity(0.2) :
                                hoveredDevice == device ? Color.white.opacity(0.1) :
                                Color.clear
                            )
                    )
                    .foregroundColor(selectedDevice == device ? .white : .gray)
                    .onHover { isHovering in
                        if isHovering {
                            hoveredDevice = device
                        } else if hoveredDevice == device {
                            hoveredDevice = nil
                        }
                    }
                }
                
                Divider()
                
                Text("Output Devices")
                    .opacity(0.6)
                    .fontWeight(.bold)
                
                if deviceManager.virtualCables.isEmpty {
                    Text("No output devices detected")
                        .foregroundColor(.gray)
                        .font(.caption)
                } else {
                    ForEach(deviceManager.virtualCables, id: \.self) { cable in
                        Button(action: {
                            selectedVirtualCable = cable
                        }) {
                            HStack {
                                Image(systemName: "cable.connector")
                                Text(cable).fontWeight(.medium)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    selectedVirtualCable == cable ? Color.blue.opacity(0.2) :
                                    hoveredVirtualCable == cable ? Color.white.opacity(0.1) :
                                    Color.clear
                                )
                        )
                        .foregroundColor(selectedVirtualCable == cable ? .white : .gray)
                        .onHover { isHovering in
                            if isHovering {
                                hoveredVirtualCable = cable
                            } else if hoveredVirtualCable == cable {
                                hoveredVirtualCable = nil
                            }
                        }
                    }
                }
                
                Divider()
                
                Text("Delay")
                    .opacity(0.6)
                    .fontWeight(.bold)
                
                HStack {
                    Slider(value: $delayValue, in: 0...300)
                    Text("\(Int(delayValue)) ms")
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
    }
}

struct LicenseTab: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("License")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your license information goes here")
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("About No Clap")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}

