# NoClap

NoClap is a macOS audio utility that adds configurable delay to audio input devices and pipes the delayed audio to a virtual cable. This is useful for content creators, streamers, and audio professionals who need to synchronize audio across multiple sources or compensate for latency issues.

## Features

- **Audio Device Selection** - Choose from all available audio input devices on your Mac
- **Virtual Cable Selection** - Select from detected virtual audio cables (BlackHole, VB-Cable, Soundflower)
- **Configurable Delay** - Adjust the delay from 0 to 300 milliseconds
- **Real-time Processing** - Low-latency audio delay powered by AudioKit
- **Simple Interface** - Easy-to-use tabbed interface with configuration summary

## Requirements

- macOS 10.13 or later
- One of the following virtual audio cables:
  - **BlackHole** (recommended) - https://github.com/ExistentialAudio/BlackHole
  - **VB-Cable** - https://vb-audio.com/Cable/
  - **Soundflower** - https://github.com/akhudek/Soundflower

### Install Virtual Cable (BlackHole)
```bash
brew install blackhole-2ch
```

## Usage

1. **Launch NoClap** - Open the application
2. **Select Input Device** - Choose your microphone from the Devices list
3. **Select Virtual Cable** - Choose your virtual cable from the Virtual Cable(s) list
4. **Set Delay** - Adjust the slider to your desired delay (0-300ms)
5. **Toggle ON** - Switch the toggle to start audio processing
6. **Configure Other Apps** - Set the virtual cable as your audio input in other applications

### Example Workflow (Streaming)
```
Microphone → NoClap (150ms delay) → VB-Cable → OBS/Streamlabs/Discord
```

This allows you to:
- Compensate for system latency
- Sync audio from different sources
- Route audio to multiple applications
- Use in conferencing apps, DAWs, or stream software

## Installation

### Prerequisites
1. Install a virtual audio cable (see Requirements)
2. Xcode 14+ with Swift 5.9+

### Build and Run

1. Clone or open the project in Xcode
2. **File** → **Add Packages...**
3. Add AudioKit: `https://github.com/AudioKit/AudioKit.git`
4. Build and run:
   ```bash
   cmd + R
   ```

The app will launch with the main window and menu bar icon.

### Building for Release
```bash
xcodebuild build -configuration Release
```

The app will appear in your Applications folder.

## License

See the **License** tab in the app for more information.

## About

For more information, see the **About** tab in the application.
