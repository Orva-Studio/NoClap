# NoClap Setup Guide

## Step-by-Step Setup

### Step 1: Install Virtual Audio Cable

Choose one option:

#### Option A: BlackHole (Recommended)
```bash
brew install blackhole-2ch
```

#### Option B: VB-Cable
1. Download from https://vb-audio.com/Cable/
2. Run installer
3. Restart macOS

#### Option C: Soundflower
```bash
brew install soundflower
```

### Step 2: Build NoClap

1. Open `NoClap.xcodeproj` in Xcode
2. **File** → **Add Packages...**
3. Enter: `https://github.com/AudioKit/AudioKit.git`
4. Select version: **Latest** (5.6+)
5. Click **Add Package**
6. Select **NoClap** target
7. Click **Add Package**
8. Build and run: **Cmd+R**

### Step 3: Configure NoClap

1. Select input device (your microphone)
2. Select virtual cable (BlackHole, VB-Cable, etc.)
3. Set delay (e.g., 150ms)
4. Toggle ON

### Step 4: Use in Other Apps

Configure your other application to use the virtual cable as input:

**OBS Studio:**
- Settings → Audio
- Mic/Aux Input → Select BlackHole/VB-Cable

**Discord:**
- User Settings → Voice & Video
- Input Device → Select BlackHole/VB-Cable

**GarageBand/Logic Pro:**
- Preferences → Audio/MIDI
- Input Device → Select BlackHole/VB-Cable

**Audacity:**
- Transport → Transport Options
- Recording Device → Select BlackHole/VB-Cable

## Troubleshooting

### "No virtual cables detected"
- Restart macOS after installing virtual cable
- Check System Preferences → Sound
- Verify the virtual cable driver is loaded

### No audio output
- Make sure NoClap toggle is ON
- Verify both input and output devices are selected
- Check that the other app is set to use the virtual cable as input

### Audio is choppy/distorted
- Lower the delay value
- Close other audio applications
- Check Activity Monitor for CPU usage

### Build fails: "No module named 'AudioKit'"
- Clean build folder: **Cmd+Shift+K**
- Delete Xcode cache: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Restart Xcode
- Re-add AudioKit package

## FAQ

**Q: Can I use NoClap with streaming?**
A: Yes! Set your streaming software (OBS, Streamlabs, etc.) to use the virtual cable as input.

**Q: What delay should I use?**
A: It depends on your use case. The delay value shifts your audio output by that many milliseconds. For example:
- 0ms: No delay (real-time audio)
- 50-100ms: Slight delay (e.g., for synchronizing with video that's slightly out of sync)
- 150-300ms: Significant delay (e.g., for compensating for external system lag or coordinating with remote participants)
- Adjust based on what you're trying to synchronize with

**Q: Does NoClap use CPU?**
A: Minimal CPU usage. AudioKit is optimized for real-time processing.

**Q: Can I adjust delay while recording?**
A: Yes! Drag the slider to adjust delay in real-time.

**Q: Do I need to keep NoClap window open?**
A: Yes, the toggle must remain ON for audio processing to continue.

## Need Help?

See `AUDIOKIT_INTEGRATION.md` for technical details about the audio processing implementation.
