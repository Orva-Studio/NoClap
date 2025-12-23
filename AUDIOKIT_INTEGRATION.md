# AudioKit Integration for NoClap

This document outlines the integration of **AudioKit** for real-time audio delay processing and routing to virtual cables.

## Why AudioKit?

AudioKit is the best choice for NoClap because:
- ✅ Modern Swift framework (actively maintained)
- ✅ Real-time audio processing with low latency
- ✅ Built on top of AVAudioEngine with better abstractions
- ✅ Easy device routing and audio node connections
- ✅ Supports macOS, iOS, and tvOS
- ✅ Comprehensive documentation and examples

## Installation

### Step 1: Add AudioKit via Swift Package Manager

1. In Xcode, go to **File** → **Add Packages...**
2. Paste this URL: `https://github.com/AudioKit/AudioKit.git`
3. Select version: **Latest** (or 5.6+)
4. Click **Add Package**
5. Select the **NoClap** target
6. Click **Add Package**

Alternatively, add to `Package.swift` if using it:
```swift
.package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.0")
```

### Step 2: Update DeviceManager.swift

```swift
import AudioKit

class DeviceManager: ObservableObject {
    @Published var devices: [String] = []
    @Published var virtualCables: [String] = []
    @Published var isProcessing: Bool = false
    
    private var audioEngine: AudioEngine?
    private var inputNode: AudioInput?
    private var delayNode: Delay?
    
    func startAudioProcessing(inputDevice: String, outputDevice: String, delayMs: Double) {
        do {
            // Initialize AudioKit engine
            audioEngine = AudioEngine()
            
            // Set input device
            if let engine = audioEngine {
                try AudioEngine.setInputDevice(inputDevice)
                try AudioEngine.setOutputDevice(outputDevice)
                
                // Create input node from microphone
                inputNode = AudioInput()
                
                // Create delay effect node
                delayNode = Delay(inputNode, time: delayMs / 1000.0)
                
                // Connect nodes: input -> delay -> output
                engine.output = delayNode
                
                // Start the audio engine
                try engine.start()
                
                DispatchQueue.main.async {
                    self.isProcessing = true
                }
            }
        } catch {
            print("Error starting audio processing: \(error)")
        }
    }
    
    func stopAudioProcessing() {
        do {
            try audioEngine?.stop()
            audioEngine = nil
            delayNode = nil
            inputNode = nil
            
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        } catch {
            print("Error stopping audio: \(error)")
        }
    }
}
```

## AudioKit Implementation Details

### Key Components

1. **AudioEngine** - Main audio processing engine
   - Manages input/output devices
   - Connects audio nodes
   - Handles real-time audio processing

2. **AudioInput** - Captures audio from microphone
   - Connects to selected input device
   - Provides audio stream to processing nodes

3. **Delay** - Applies delay effect
   - Real-time delay buffer (replaces AudioDelayProcessor)
   - Configurable delay time
   - Low-latency processing

4. **Output** - Routes to virtual cable
   - Connects to selected output device
   - Sends processed audio to VB-Cable, BlackHole, etc.

### Delay Time Adjustment

To allow real-time delay adjustment:

```swift
if let delay = delayNode {
    delay.time = newDelayMs / 1000.0  // Convert ms to seconds
}
```

### Audio Routing Flow

```
[Microphone Input] 
    ↓
[AudioInput Node]
    ↓
[Delay Node] (applies delay effect)
    ↓
[Audio Engine Output]
    ↓
[Virtual Cable (VB-Cable/BlackHole)]
```

## Usage in ContentView

The toggle will now use AudioKit for actual audio processing:

```swift
.onChange(of: isEnabled) {
    if isEnabled && !selectedDevice.isEmpty && selectedVirtualCable != nil {
        deviceManager.startAudioProcessing(
            inputDevice: selectedDevice,
            outputDevice: selectedVirtualCable!,
            delayMs: delayValue
        )
    } else {
        deviceManager.stopAudioProcessing()
    }
}
```

## Virtual Cable Setup

Users need to install a virtual audio device:

### Option 1: BlackHole (Recommended)
```bash
brew install blackhole-2ch
```
Then select "BlackHole 2ch" as output device in NoClap

### Option 2: VB-Cable
- Download from: https://vb-audio.com/Cable/
- Install and restart macOS

### Option 3: Soundflower (Legacy)
```bash
brew install soundflower
```

## Testing

1. Install a virtual cable (BlackHole, VB-Cable, or Soundflower)
2. In NoClap:
   - Select **Microphone** → Input device
   - Select **Virtual Cable** → Output device
   - Set delay (e.g., 150ms)
   - Toggle ON
3. Open another audio app (Audacity, GarageBand, etc.)
4. Set input to the virtual cable
5. Speak into microphone and hear delayed audio in the other app

## Troubleshooting

### "No module named 'AudioKit'"
- Run `Cmd+Shift+K` to clean build folder
- Restart Xcode
- Re-add the package

### No audio coming through
- Check both input and output devices are selected
- Verify virtual cable is installed and working
- Check System Preferences → Sound settings

### Audio is distorted or choppy
- Reduce delay value
- Check system CPU usage
- Try increasing AudioKit's buffer size

## Next Steps

1. ✅ Add AudioKit to project
2. ✅ Replace DeviceManager audio logic with AudioKit
3. ✅ Test with BlackHole virtual cable
4. ✅ Handle real-time delay adjustment
5. ✅ Add error handling and user feedback
6. Optional: Add effects (EQ, compression) using AudioKit Nodes

## References

- AudioKit GitHub: https://github.com/AudioKit/AudioKit
- AudioKit Documentation: https://audiokit.io/
- AudioKit Playground: https://audiokit.io/playground/
- Core Audio Programming Guide: https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/CoreAudioOverview/

## License

AudioKit is licensed under the MIT License
