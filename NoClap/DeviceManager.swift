//
//  DeviceManager.swift
//  NoClap
//
//  Created by Richard Oliver Bray on 29/11/2025.
//

import Foundation
import Combine

struct APIDevice: Codable {
    let id: Int
    let name: String
    let type: String
    let channels: Int
}

struct APIStatus: Codable {
    let is_running: Bool
}

class DeviceManager: ObservableObject {
    @Published var devices: [String] = []
    @Published var virtualCables: [String] = []
    @Published var isProcessing: Bool = false
    
    // Maps to store Name -> ID mapping
    private var inputMap: [String: Int] = [:]
    private var outputMap: [String: Int] = [:]
    
    private let baseURL = "http://127.0.0.1:8000"
    private var serverProcess: Process?
    
    init() {
        startPythonServer()
        
        // Give the server a moment to warm up before first visual refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.refreshDevices()
            self.checkServerStatus()
        }
    }
    
    deinit {
        stopPythonServer()
    }
    
    private func stopPythonServer() {
        if let process = serverProcess {
            process.terminate()
            serverProcess = nil
        }
    }
    
    private func startPythonServer() {
        // 1. Locate server.py
        // Check Bundle first (Release mode), then fallback to hardcoded path (Dev mode)
        var scriptPath = Bundle.main.path(forResource: "server", ofType: "py")
        
        if scriptPath == nil {
            // Fallback for development if file isn't in bundle resources yet
            // Assuming the standard project structure: ProjectRoot/server.py
            let devPath = "/Users/richardoliverbray/NoClap/server.py"
            if FileManager.default.fileExists(atPath: devPath) {
                scriptPath = devPath
            }
        }
        
        guard let finalScriptPath = scriptPath else {
            print("❌ Could not find server.py")
            return
        }
        
        // 2. Locate python3
        // GUI apps don't share the Shell's PATH, so we check standard locations
        let pythonPaths = [
            "/opt/homebrew/bin/python3", // Apple Silicon Homebrew
            "/usr/local/bin/python3",    // Intel Homebrew
            "/usr/bin/python3"           // System (might lack dependencies)
        ]
        
        guard let pythonPath = pythonPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            print("❌ Could not find python3 executable")
            return
        }
        
        print("🚀 Launching Python Server...")
        print("   Interpreter: \(pythonPath)")
        print("   Script: \(finalScriptPath)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [finalScriptPath]
        
        // Optional: Capture output for debugging (logs inside Xcode console)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8), !line.isEmpty {
                print("[Server] \(line.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        do {
            try process.run()
            self.serverProcess = process
        } catch {
            print("❌ Failed to launch server: \(error)")
        }
    }
    
    func refreshDevices() {
        guard let url = URL(string: "\(baseURL)/devices") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Error fetching devices: \(String(describing: error))")
                return
            }
            
            do {
                let apiDevices = try JSONDecoder().decode([APIDevice].self, from: data)
                
                var newInputs: [String] = []
                var newOutputs: [String] = []
                var newInputMap: [String: Int] = [:]
                var newOutputMap: [String: Int] = [:]
                
                for dev in apiDevices {
                    if dev.type == "input" {
                        newInputs.append(dev.name)
                        newInputMap[dev.name] = dev.id
                    } else if dev.type == "output" {
                        newOutputs.append(dev.name)
                        newOutputMap[dev.name] = dev.id
                    }
                }
                
                DispatchQueue.main.async {
                    self.devices = newInputs
                    self.virtualCables = newOutputs // Using existing UI property name
                    self.inputMap = newInputMap
                    self.outputMap = newOutputMap
                }
                
            } catch {
                print("Error decoding devices: \(error)")
            }
        }.resume()
    }
    
    func checkServerStatus() {
        guard let url = URL(string: "\(baseURL)/status") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            
            do {
                let status = try JSONDecoder().decode(APIStatus.self, from: data)
                DispatchQueue.main.async {
                    self.isProcessing = status.is_running
                }
            } catch {
                print("Error checking status: \(error)")
            }
        }.resume()
    }
    
    func startAudioProcessing(inputDevice: String, outputDevice: String, delayMs: Double) {
        guard let inputId = inputMap[inputDevice],
              let outputId = outputMap[outputDevice],
              let url = URL(string: "\(baseURL)/start") else {
            print("Invalid device selection or URL")
            return
        }
        
        let body: [String: Any] = [
            "input_device_id": inputId,
            "output_device_id": outputId,
            "delay_ms": delayMs
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error starting audio: \(error)")
                DispatchQueue.main.async {
                    self?.isProcessing = false
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.isProcessing = true
                }
            } else {
                 print("Server returned error")
                 DispatchQueue.main.async { self?.isProcessing = false }
            }
        }.resume()
    }
    
    func stopAudioProcessing() {
        guard let url = URL(string: "\(baseURL)/stop") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.isProcessing = false
            }
        }.resume()
    }
    
    func updateDelay(_ delayMs: Double) {
        // Option to add live update endpoint later
        print("Delay update requested: \(delayMs)")
        // For now, you might need to stop/start to update delay effectively
        // or add a /delay endpoint to Python
    }
}
