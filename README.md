# Speech2Text

Offline Speech-to-Text für macOS mit OpenAI Whisper. Diktiere in jede Anwendung mit einem globalen Hotkey.

## Features

- **100% Offline** - Keine Cloud, keine Daten werden gesendet
- **Globaler Hotkey** - Ctrl+Shift+D funktioniert in jeder App
- **Schnell** - Nutzt faster-whisper mit int8-Quantisierung
- **Deutsch optimiert** - Standardmäßig auf Deutsch eingestellt
- **Native macOS App** - Kompilierte .app für sichere Accessibility-Berechtigung
- **Autostart** - Startet automatisch beim Login

## Systemanforderungen

- macOS 10.15+ (Catalina oder neuer)
- Apple Silicon (M1/M2/M3) oder Intel Mac
- ~700 MB Speicherplatz

## Installation

### Für Benutzer (vorkompilierte App)

```bash
# 1. Repository klonen
git clone https://github.com/yourusername/Speech2Text.git
cd Speech2Text

# 2. Installieren
./install.sh
```

### Für Entwickler (selbst kompilieren)

```bash
# 1. Repository klonen
git clone https://github.com/yourusername/Speech2Text.git
cd Speech2Text

# 2. App bauen
./build.sh

# 3. Installieren
./install.sh
```

### Accessibility-Berechtigung erteilen

Nach der Installation muss einmalig die Accessibility-Berechtigung erteilt werden:

1. Öffne **Systemeinstellungen**
2. Gehe zu **Datenschutz & Sicherheit** → **Bedienungshilfen**
3. Klicke auf das **Schloss-Symbol** und authentifiziere dich
4. Klicke auf **+**
5. Navigiere zu `/Applications/`
6. Wähle **Speech2Text.app** und klicke **Öffnen**
7. Aktiviere die **Checkbox**

Danach Speech2Text neu starten:
```bash
./speech2text-stop.sh && ./speech2text-start.sh
```

## Verwendung

### Diktieren

1. **Ctrl+Shift+D** drücken → Aufnahme startet (🎤)
2. Sprechen
3. **Ctrl+Shift+D** erneut drücken → Text wird transkribiert und eingefügt (✅)

### Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `./speech2text-start.sh` | Speech2Text starten |
| `./speech2text-stop.sh` | Speech2Text stoppen |
| `./install.sh` | Installieren (nach build.sh) |
| `./uninstall.sh` | Vollständig deinstallieren |
| `./build.sh` | App neu kompilieren |
| `tail -f /tmp/speech2text.log` | Log anzeigen |

## Deinstallation

```bash
./uninstall.sh
```

Der Uninstaller:
- Stoppt alle laufenden Prozesse
- Entfernt die App aus `/Applications`
- Entfernt den LaunchAgent (Autostart)
- Löscht temporäre Dateien
- Optional: Löscht das Whisper-Modell (~500MB)

**Vergiss nicht:** Entferne Speech2Text aus den Accessibility-Berechtigungen in den Systemeinstellungen.

## Konfiguration

### Whisper-Modell ändern

In `speech2text/transcribe.py`:

```python
MODEL_SIZE = "small"  # Optionen: tiny, base, small, medium, large
```

| Modell | Größe | Geschwindigkeit | Genauigkeit |
|--------|-------|-----------------|-------------|
| tiny   | ~75MB | Sehr schnell    | Niedrig     |
| base   | ~150MB| Schnell         | Mittel      |
| small  | ~500MB| Mittel          | Gut         |
| medium | ~1.5GB| Langsam         | Sehr gut    |
| large  | ~3GB  | Sehr langsam    | Exzellent   |

**Hinweis:** Nach Änderung des Modells muss die App neu kompiliert werden (`./build.sh`).

### Sprache ändern

In `speech2text/transcribe.py`:

```python
segments, info = self.model.transcribe(
    audio_file,
    language="de",  # Ändern zu "en", "fr", etc.
    ...
)
```

### Hotkey ändern

In `speech2text/main.py`:

```python
HOTKEY_COMBINATION = "<ctrl>+<shift>+d"  # Ändere nach Bedarf
HOTKEY_DISPLAY = "Ctrl+Shift+D"
```

## Fehlerbehebung

### Hotkey funktioniert nicht

1. Prüfe ob Speech2Text.app in den Accessibility-Berechtigungen ist
2. Entferne und füge die App erneut hinzu
3. Starte neu: `./speech2text-stop.sh && ./speech2text-start.sh`
4. Prüfe den Log: `tail -f /tmp/speech2text.log`

### "This process is not trusted"

Speech2Text.app hat keine Accessibility-Berechtigung. Siehe Abschnitt "Accessibility-Berechtigung erteilen".

### Kein Text erkannt

- Prüfe Mikrofon-Berechtigung: Systemeinstellungen → Datenschutz & Sicherheit → Mikrofon
- Sprich lauter und deutlicher
- Mindestens 1-2 Sekunden sprechen

### App startet nicht beim Login

```bash
launchctl unload ~/Library/LaunchAgents/com.speech2text.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.speech2text.plist
```

### Prozess reagiert nicht

```bash
./speech2text-stop.sh
pkill -f "Speech2Text"
./speech2text-start.sh
```

## Dateistruktur

```
Speech2Text/
├── speech2text/          # Python-Quellcode
│   ├── main.py           # Hauptprogramm, Hotkey-Handling
│   ├── audio.py          # Mikrofon-Aufnahme
│   ├── transcribe.py     # Whisper-Integration
│   └── paste.py          # Text-Einfügung via Clipboard
├── dist/
│   └── Speech2Text.app   # Kompilierte macOS App
├── build.sh              # Build-Script
├── install.sh            # Installer
├── uninstall.sh          # Uninstaller
├── speech2text-start.sh  # Start-Script
├── speech2text-stop.sh   # Stop-Script
├── Speech2Text.spec      # PyInstaller-Konfiguration
├── requirements.txt      # Python-Abhängigkeiten
└── README.md
```

## Technische Details

- **Whisper:** faster-whisper mit CTranslate2 (int8-Quantisierung)
- **Hotkey:** pynput GlobalHotKeys
- **Audio:** sounddevice (16kHz, mono)
- **Clipboard:** pyperclip + pynput für Cmd+V
- **Build:** PyInstaller für native macOS App

## Lizenz

MIT License
