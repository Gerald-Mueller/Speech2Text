"""Whisper Transkriptions-Modul"""

import io
import sys
from faster_whisper import WhisperModel

MODEL_SIZE = "small"  # Gute Balance zwischen Genauigkeit und Geschwindigkeit


class Transcriber:
    """Transkribiert Audio mit Whisper."""

    def __init__(self, model_size: str = MODEL_SIZE):
        self.model_size = model_size
        self.model: WhisperModel | None = None

    def load_model(self) -> None:
        """Lädt das Whisper-Modell (beim ersten Aufruf)."""
        if self.model is None:
            print(f"Lade Whisper-Modell '{self.model_size}'...", file=sys.stderr)
            self.model = WhisperModel(
                self.model_size,
                device="cpu",  # Für M1/M2 Mac
                compute_type="int8",  # Schneller auf CPU
            )
            print("Modell geladen!", file=sys.stderr)

    def transcribe(self, audio_data: bytes) -> str:
        """Transkribiert Audio-Daten zu Text."""
        if not audio_data:
            return ""

        self.load_model()

        # Whisper erwartet eine Datei oder einen Pfad
        audio_file = io.BytesIO(audio_data)

        segments, info = self.model.transcribe(
            audio_file,
            language="de",  # Deutsch
            beam_size=5,
            vad_filter=True,  # Filtert Stille
        )

        # Kombiniere alle Segmente
        text_parts = [segment.text.strip() for segment in segments]
        return " ".join(text_parts)
