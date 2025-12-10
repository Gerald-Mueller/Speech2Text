# Speech2Text - Architektur-Dokumentation

## Überblick

Speech2Text ist eine native macOS-Anwendung zur Offline-Spracherkennung. Sie verwendet OpenAI's Whisper-Modell (via faster-whisper) für die lokale Transkription und fügt den erkannten Text in die aktive Anwendung ein.

Die App wird mit PyInstaller zu einer eigenständigen .app kompiliert, die ihre eigene Accessibility-Berechtigung erhält.

```
┌──────────────────────────────────────────────────────────────┐
│                        macOS                                 │
│  ┌─────────────┐    ┌─────────────┐     ┌─────────────────┐  │
│  │   Hotkey    │    │   Audio     │     │   Clipboard     │  │
│  │  (pynput)   │    │(sounddevice)│     │(pyperclip+pynput│  │
│  └──────┬──────┘    └──────┬──────┘     └────────┬────────┘  │
│         │                  │                     │           │
│  ┌──────┴──────────────────┴─────────────────────┴─────────┐ │
│  │              Speech2Text.app (PyInstaller)              │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐   │ │
│  │  │  main.py │→ │ audio.py │→ │transcribe│→ │paste.py│   │ │
│  │  │ (Hotkey) │  │(Aufnahme)│  │   .py    │  │(Einfüg)│   │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └────────┘   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                              │                               │
│                    ┌─────────┴─────────┐                     │
│                    │  faster-whisper   │                     │
│                    │  (Whisper Model)  │                     │
│                    └───────────────────┘                     │
└──────────────────────────────────────────────────────────────┘
```

## Build & Deployment

### PyInstaller Build

Die App wird mit PyInstaller kompiliert (`Speech2Text.spec`):

```bash
./build.sh  # Erstellt dist/Speech2Text.app
```

**Warum PyInstaller?**
- Erzeugt native macOS App mit eigener Bundle-ID
- App erhält eigene Accessibility-Berechtigung
- Kein globales Python/Terminal nötig
- Alle Dependencies eingebettet (~170MB)

### Installation

```bash
./install.sh  # Kopiert nach /Applications/Speech2Text.app
```

1. App wird nach `/Applications/Speech2Text.app` kopiert
2. LaunchAgent für Autostart erstellt
3. Benutzer erteilt einmalig Accessibility-Berechtigung

## Module

### main.py - Hauptprogramm

**Verantwortlichkeiten:**
- Globales Hotkey-Handling via `pynput.keyboard.GlobalHotKeys`
- Single-Instance-Management via File-Lock (`fcntl.flock`)
- Heartbeat-Thread verhindert Prozess-Suspension
- Koordination zwischen Audio-Aufnahme und Transkription
- Signal-Handling für sauberes Herunterfahren

**Single-Instance-Mechanismus:**
```python
# Lock-Datei: /tmp/speech2text.lock
# PID-Datei: /tmp/speech2text.pid

fd = os.open(LOCK_FILE, os.O_CREAT | os.O_RDWR)
fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)  # Non-blocking
```

Der File-Lock ist atomar und wird automatisch freigegeben wenn:
- Der Prozess beendet wird
- Das System abstürzt
- `release_lock()` aufgerufen wird

**Hotkey-Handling:**
```python
HOTKEY_COMBINATION = "<ctrl>+<shift>+d"

with keyboard.GlobalHotKeys({HOTKEY_COMBINATION: self.on_hotkey}) as listener:
    listener.join()
```

`GlobalHotKeys` ist zuverlässiger als manuelles Key-Tracking, da es:
- Modifier-Kombinationen korrekt erkennt
- Keine Race-Conditions hat
- System-Events direkt abfängt

**Heartbeat-Thread:**
```python
def _heartbeat(self) -> None:
    """Verhindert, dass der Prozess suspendiert wird."""
    while self.running:
        time.sleep(HEARTBEAT_INTERVAL)  # 30 Sekunden
```

### audio.py - Audio-Aufnahme

**Verantwortlichkeiten:**
- Mikrofon-Zugriff via `sounddevice`
- Audio-Streaming in Echtzeit
- Konvertierung zu WAV-Format

**Konfiguration:**
```python
SAMPLE_RATE = 16000  # Whisper erwartet 16kHz
CHANNELS = 1         # Mono
dtype = np.float32   # 32-bit Float für Verarbeitung
```

**Ablauf:**
1. `start()`: Öffnet InputStream, registriert Callback
2. Callback: Sammelt Audio-Chunks in Liste
3. `stop()`: Schließt Stream, konkateniert Chunks, konvertiert zu 16-bit WAV

**Memory-Handling:**
```python
# Audio wird in Memory gehalten (kein Temp-File)
wav_buffer = io.BytesIO()
with wave.open(wav_buffer, "wb") as wav_file:
    wav_file.writeframes(audio_int16.tobytes())
return wav_buffer.getvalue()
```

### transcribe.py - Whisper-Integration

**Verantwortlichkeiten:**
- Laden des Whisper-Modells (lazy loading)
- Audio-zu-Text-Transkription

**Modell-Konfiguration:**
```python
self.model = WhisperModel(
    "small",           # Modell-Größe
    device="cpu",      # CPU für M1/M2/M3 Macs
    compute_type="int8"  # Quantisierung für Geschwindigkeit
)
```

**Transkriptions-Parameter:**
```python
segments, info = self.model.transcribe(
    audio_file,
    language="de",      # Sprache
    beam_size=5,        # Beam-Search Breite
    vad_filter=True,    # Voice Activity Detection
)
```

**VAD-Filter:**
Der `vad_filter` entfernt Stille-Segmente vor der Transkription, was:
- Geschwindigkeit erhöht
- Halluzinationen bei Stille reduziert

### paste.py - Text-Einfügung

**Verantwortlichkeiten:**
- Text in Clipboard kopieren
- Cmd+V simulieren via pynput

**Implementierung:**
```python
from pynput.keyboard import Controller, Key

keyboard = Controller()

def paste_text(text: str) -> None:
    # Text in Clipboard
    pyperclip.copy(text)
    time.sleep(0.1)

    # Cmd+V via pynput (nutzt App-Berechtigung)
    keyboard.press(Key.cmd)
    keyboard.press('v')
    keyboard.release('v')
    keyboard.release(Key.cmd)
```

**Warum pynput statt AppleScript?**
- pynput läuft im selben Prozess wie die App
- Teilt die Accessibility-Berechtigung der App
- Kein separates `osascript` das eigene Berechtigung bräuchte

## Datenfluss

```
1. Hotkey (Ctrl+Shift+D)
       │
       ▼
2. on_hotkey() → Toggle Recording
       │
       ├─► start_recording()
       │       │
       │       ▼
       │   AudioRecorder.start()
       │       │
       │       ▼
       │   [Audio-Streaming läuft]
       │
       └─► stop_recording()
               │
               ▼
           AudioRecorder.stop() → WAV bytes
               │
               ▼
           Transcriber.transcribe(wav) → Text
               │
               ▼
           paste_text(text) → Clipboard + Cmd+V
```

## Threading-Modell

```
Main Thread
    │
    ├── GlobalHotKeys Listener (blockierend)
    │       │
    │       └── on_hotkey() Callback
    │               │
    │               └── Alle Operationen synchron
    │
    ├── Heartbeat Thread (daemon)
    │       │
    │       └── Periodic sleep, verhindert Suspension
    │
Audio Thread (von sounddevice)
    │
    └── _audio_callback() → Schreibt in self.audio_data
```

**Wichtig:** Die Audio-Aufnahme läuft in einem separaten Thread (von sounddevice verwaltet), aber alle anderen Operationen sind synchron im Main Thread. Dies vereinfacht das Locking.

## Fehlerbehandlung

### Kritische Fehler (Programm beenden)
- Lock kann nicht erworben werden (andere Instanz läuft)
- Whisper-Modell kann nicht geladen werden

### Nicht-kritische Fehler (Warnung ausgeben)
- Keine Audio-Daten aufgenommen
- Kein Text erkannt
- Einfügen fehlgeschlagen

```python
try:
    audio_data = self.recorder.stop()
    text = self.transcriber.transcribe(audio_data)
    paste_text(text)
except Exception as e:
    print(f"❌ Fehler: {e}", file=sys.stderr)
finally:
    self.is_processing = False  # Immer zurücksetzen!
```

## Sicherheit

### Datenschutz
- **Keine Netzwerk-Verbindungen** - Alles läuft lokal
- **Keine Logs von Transkriptionen** - Nur Status-Meldungen
- **Audio wird nicht gespeichert** - Nur in Memory während Verarbeitung

### Berechtigungen
- **Accessibility** - Für GlobalHotKeys und Cmd+V (nur Speech2Text.app)
- **Mikrofon** - Für Audio-Aufnahme (von sounddevice benötigt)

### Warum native App?
- Nur `/Applications/Speech2Text.app` erhält Accessibility-Berechtigung
- Python und Terminal brauchen KEINE globale Berechtigung
- Minimale Angriffsfläche

## Performance

### Modell-Laden
- Einmalig beim Start (~2-5 Sekunden für "small")
- Modell bleibt im RAM

### Transkription
- ~1-3 Sekunden für kurze Sätze (< 10 Sekunden Audio)
- Linear mit Audio-Länge

### Speicher
- ~170MB für Speech2Text.app
- ~500MB für Whisper "small" Modell (in ~/.cache)
- ~50-100MB für Audio-Buffer (abhängig von Aufnahmelänge)

## Dateistruktur

```
/Applications/Speech2Text.app     # Installierte App
~/Library/LaunchAgents/
    com.speech2text.plist         # Autostart-Konfiguration
/tmp/
    speech2text.lock              # Single-Instance Lock
    speech2text.pid               # Prozess-ID
    speech2text.log               # Log-Ausgabe
~/.cache/huggingface/hub/
    models--Systran--faster-whisper-small/  # Whisper-Modell
```

## Erweiterungsmöglichkeiten

1. **Streaming-Transkription** - Text während des Sprechens anzeigen
2. **Mehrsprachigkeit** - Automatische Spracherkennung
3. **Shortcuts anpassen** - Konfigurierbare Hotkeys (UI)
4. **Menubar-App** - Status-Icon mit Menü
5. **GPU-Unterstützung** - Schnellere Transkription auf Metal
