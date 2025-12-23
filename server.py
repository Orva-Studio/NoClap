
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import pyaudio
import numpy as np
import threading
import time
from collections import deque
import atexit

app = FastAPI()

# --- Audio Logic (From your script) ---

class VirtualMicrophone:
    """Virtual microphone with proper cleanup and thread management"""
    
    def __init__(self, delay_ms=200, sample_rate=44100, chunk_size=1024,
                 input_device=None, output_device=None):
        self.delay_ms = delay_ms
        self.sample_rate = sample_rate
        self.chunk_size = chunk_size
        self.input_device = input_device
        self.output_device = output_device
        
        # Threading control
        self._stop_event = threading.Event()
        self._audio_thread = None
        
        # Audio components
        self._pa = None
        self._input_stream = None
        self._output_stream = None
        
        # Calculate buffer size needed for delay
        delay_samples = max(1, int(delay_ms * sample_rate / 1000))
        buffer_list = [0.0] * delay_samples
        self._delay_buffer = deque(buffer_list, maxlen=int(delay_samples))
    
    def _process_audio(self):
        """Process audio in separate thread with proper cleanup"""
        try:
            self._pa = pyaudio.PyAudio()
            
            # Input stream (physical microphone)
            self._input_stream = self._pa.open(
                format=pyaudio.paFloat32,
                channels=1,
                rate=self.sample_rate,
                input=True,
                frames_per_buffer=self.chunk_size,
                input_device_index=self.input_device
            )
            
            # Output stream (virtual audio device)
            if self.output_device is None:
                raise ValueError("Output device not specified")
                
            device_info = self._pa.get_device_info_by_index(self.output_device)
            max_output_channels = int(device_info.get('maxOutputChannels', 0))
            max_input_channels = int(device_info.get('maxInputChannels', 0))
            
            if max_output_channels == 0 and max_input_channels > 0:
                channels = min(1, max_input_channels)
                stream_type = 'input'
            else:
                channels = min(1, max_output_channels)
                stream_type = 'output'
            
            self._output_stream = self._pa.open(
                format=pyaudio.paFloat32,
                channels=channels,
                rate=self.sample_rate,
                output=(stream_type == 'output'),
                input=(stream_type == 'input'),
                frames_per_buffer=self.chunk_size,
                output_device_index=self.output_device if stream_type == 'output' else None,
                input_device_index=self.output_device if stream_type == 'input' else None
            )
            
            print(f"🎤 Audio processing started: Input {self.input_device} -> Output {self.output_device}")
            
            while not self._stop_event.is_set():
                try:
                    input_data = self._input_stream.read(self.chunk_size, exception_on_overflow=False)
                    if self._stop_event.is_set(): break
                        
                    input_audio = np.frombuffer(input_data, dtype=np.float32)
                    
                    output_audio = np.zeros_like(input_audio)
                    for i, sample in enumerate(input_audio):
                        self._delay_buffer.append(sample)
                        output_audio[i] = self._delay_buffer[0]
                    
                    if not self._stop_event.is_set():
                        self._output_stream.write(output_audio.tobytes())
                        
                except Exception as e:
                    print(f"Loop error: {e}")
                    break
                    
        except Exception as e:
            print(f"❌ Failed to initialize audio streams: {e}")
        finally:
            self._cleanup_streams()
    
    def _cleanup_streams(self):
        try:
            if self._input_stream:
                self._input_stream.stop_stream()
                self._input_stream.close()
            if self._output_stream:
                self._output_stream.stop_stream()
                self._output_stream.close()
            if self._pa:
                self._pa.terminate()
        except Exception:
            pass
        self._input_stream = None
        self._output_stream = None
        self._pa = None
    
    def start(self):
        if self._audio_thread and self._audio_thread.is_alive():
            return False
        self._stop_event.clear()
        self._audio_thread = threading.Thread(target=self._process_audio, daemon=True)
        self._audio_thread.start()
        return True
    
    def stop(self):
        if self._audio_thread and self._audio_thread.is_alive():
            self._stop_event.set()
            self._audio_thread.join(timeout=2.0)
        self._cleanup_streams()
    
    def is_running(self):
        return self._audio_thread and self._audio_thread.is_alive()

# Global State
mic_instance: Optional[VirtualMicrophone] = None

# --- API Models ---

class DeviceInfo(BaseModel):
    id: int
    name: str
    type: str # 'input' or 'output'

class StartRequest(BaseModel):
    input_device_id: int
    output_device_id: int
    delay_ms: float

class StatusResponse(BaseModel):
    is_running: bool
    input_device: Optional[int]
    output_device: Optional[int]
    delay_ms: Optional[float]

# --- Endpoints ---

@app.get("/devices")
def get_devices():
    p = pyaudio.PyAudio()
    devices = []
    
    try:
        count = p.get_device_count()
        for i in range(count):
            try:
                info = p.get_device_info_by_index(i)
                name = str(info.get('name', 'Unknown'))
                
                # Safely cast channels to int, defaulting to 0
                try:
                    max_in = int(info.get('maxInputChannels', 0))
                except (ValueError, TypeError):
                    max_in = 0
                    
                try:
                    max_out = int(info.get('maxOutputChannels', 0))
                except (ValueError, TypeError):
                    max_out = 0
                
                if max_in > 0:
                    devices.append({
                        "id": i,
                        "name": name,
                        "type": "input",
                        "channels": max_in
                    })
                
                # For output, include virtual devices
                if max_out > 0 or "cable" in name.lower() or "blackhole" in name.lower():
                     devices.append({
                        "id": i,
                        "name": name,
                        "type": "output",
                        "channels": max_out
                    })
            except Exception:
                continue
    finally:
        p.terminate()
        
    return devices

@app.post("/start")
def start_mic(req: StartRequest):
    global mic_instance
    
    if mic_instance and mic_instance.is_running():
        mic_instance.stop()
    
    mic_instance = VirtualMicrophone(
        delay_ms=int(req.delay_ms),
        sample_rate=44100,
        input_device=req.input_device_id,
        output_device=req.output_device_id
    )
    
    success = mic_instance.start()
    if not success:
        raise HTTPException(status_code=500, detail="Failed to start audio engine")
    
    return {"status": "started"}

@app.post("/stop")
def stop_mic():
    global mic_instance
    if mic_instance:
        mic_instance.stop()
        mic_instance = None
    return {"status": "stopped"}

@app.get("/status", response_model=StatusResponse)
def get_status():
    inst = mic_instance
    running = inst is not None and inst.is_running()
    
    if running and inst:
        return {
            "is_running": True,
            "input_device": inst.input_device,
            "output_device": inst.output_device,
            "delay_ms": inst.delay_ms
        }
    else:
        return {
            "is_running": False,
            "input_device": None,
            "output_device": None,
            "delay_ms": None
        }

@app.on_event("shutdown")
def shutdown_event():
    stop_mic()

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
