"""Audio-Aufnahme Modul"""

import io
import wave
import numpy as np
import sounddevice as sd

SAMPLE_RATE = 16000  # Whisper erwartet 16kHz
CHANNELS = 1


class AudioRecorder:
    """Nimmt Audio vom Mikrofon auf."""

    def __init__(self, sample_rate: int = SAMPLE_RATE):
        self.sample_rate = sample_rate
        self.recording = False
        self.audio_data: list[np.ndarray] = []

    def start(self) -> None:
        """Startet die Aufnahme."""
        self.audio_data = []
        self.recording = True
        self.stream = sd.InputStream(
            samplerate=self.sample_rate,
            channels=CHANNELS,
            dtype=np.float32,
            callback=self._audio_callback,
        )
        self.stream.start()

    def stop(self) -> bytes:
        """Stoppt die Aufnahme und gibt WAV-Daten zurück."""
        self.recording = False
        self.stream.stop()
        self.stream.close()

        if not self.audio_data:
            return b""

        # Kombiniere alle Audio-Chunks
        audio = np.concatenate(self.audio_data)

        # Konvertiere zu 16-bit PCM
        audio_int16 = (audio * 32767).astype(np.int16)

        # Erstelle WAV in Memory
        wav_buffer = io.BytesIO()
        with wave.open(wav_buffer, "wb") as wav_file:
            wav_file.setnchannels(CHANNELS)
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(self.sample_rate)
            wav_file.writeframes(audio_int16.tobytes())

        return wav_buffer.getvalue()

    def _audio_callback(
        self, indata: np.ndarray, frames: int, time_info, status
    ) -> None:
        """Callback für Audio-Stream."""
        if self.recording:
            self.audio_data.append(indata.copy())
