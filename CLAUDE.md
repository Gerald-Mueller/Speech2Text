# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Speech2Text - Eine offline Speech-to-Text Anwendung für macOS, die Whisper lokal ausführt. Das Tool ermöglicht Diktat in jede Anwendung via globalem Hotkey (Ctrl+Shift+D).

Die App wird mit PyInstaller zu einer nativen macOS App kompiliert, die ihre eigene Accessibility-Berechtigung erhält (kein globales Python/Terminal nötig).

## Development Commands

```bash
# App bauen (kompiliert mit PyInstaller)
./build.sh

# App installieren (nach /Applications)
./install.sh

# App starten
./speech2text-start.sh

# App stoppen
./speech2text-stop.sh

# App deinstallieren
./uninstall.sh

# Log anzeigen
tail -f /tmp/speech2text.log
```

### Entwicklung ohne Kompilierung

```bash
# Virtual Environment aktivieren
source venv/bin/activate

# Direkt ausführen (benötigt Terminal Accessibility-Berechtigung)
python -m speech2text

# Abhängigkeiten installieren
pip install -r requirements.txt
```

## Architecture

```
Speech2Text/
├── speech2text/           # Python-Quellcode
│   ├── __init__.py        # Package init
│   ├── __main__.py        # Entry point für python -m speech2text
│   ├── main.py            # Hauptprogramm, Hotkey-Handling, Single-Instance
│   ├── audio.py           # AudioRecorder - Mikrofon-Aufnahme mit sounddevice
│   ├── transcribe.py      # Transcriber - Whisper-Integration via faster-whisper
│   └── paste.py           # Text-Einfügung via pynput (Cmd+V)
├── dist/
│   └── Speech2Text.app    # Kompilierte macOS App (PyInstaller)
├── build.sh               # Build-Script
├── install.sh             # Installer → /Applications/Speech2Text.app
├── uninstall.sh           # Vollständiger Uninstaller
├── speech2text-start.sh   # Start via `open -a`
├── speech2text-stop.sh    # Stop + Cleanup
├── Speech2Text.spec       # PyInstaller-Konfiguration
├── run_speech2text.py     # Entry point für PyInstaller
├── requirements.txt       # Python-Abhängigkeiten
└── venv/                  # Virtual Environment (nur für Entwicklung/Build)
```

### Kernkomponenten

- **main.py**: Verwendet `pynput.keyboard.GlobalHotKeys` für Hotkey-Handling. Single-Instance via `fcntl.flock()`. Heartbeat-Thread verhindert Prozess-Suspension.
- **audio.py**: Nimmt Audio mit 16kHz Sample Rate auf (Whisper-Anforderung). Speichert als WAV in Memory.
- **transcribe.py**: Lädt `faster-whisper` Modell (small), transkribiert auf CPU mit int8.
- **paste.py**: Kopiert Text in Clipboard und simuliert Cmd+V via pynput (teilt Accessibility-Berechtigung mit der App).

### Build-Prozess

1. `build.sh` erstellt Virtual Environment falls nötig
2. Installiert PyInstaller und Dependencies
3. Kompiliert mit `Speech2Text.spec` zu nativer macOS App
4. Output: `dist/Speech2Text.app` (~170MB)

### Installation

1. `install.sh` kopiert App nach `/Applications/Speech2Text.app`
2. Erstellt LaunchAgent für Autostart (`~/Library/LaunchAgents/com.speech2text.plist`)
3. Benutzer muss einmalig Accessibility-Berechtigung erteilen

### Wichtige Dateien (Runtime)

- `/Applications/Speech2Text.app` - Installierte App
- `~/Library/LaunchAgents/com.speech2text.plist` - Autostart-Konfiguration
- `/tmp/speech2text.lock` - File-Lock für Single-Instance
- `/tmp/speech2text.pid` - PID für externes Stoppen
- `/tmp/speech2text.log` - Log-Ausgabe
- `~/.cache/huggingface/hub/models--Systran--faster-whisper-small` - Whisper-Modell (~500MB)

## Hotkey

- **Ctrl+Shift+D** - Toggle Aufnahme (Start/Stop)
- Konfigurierbar in `speech2text/main.py`: `HOTKEY_COMBINATION`

## Accessibility-Berechtigung

Die kompilierte App (`/Applications/Speech2Text.app`) benötigt Accessibility-Berechtigung für:
1. GlobalHotKeys (Tastatureingaben erkennen)
2. Cmd+V simulieren (Text einfügen)

Nur die App selbst braucht die Berechtigung - nicht Python oder Terminal global.
