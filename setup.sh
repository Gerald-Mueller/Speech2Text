#!/bin/bash
# Speech2Text Setup Script für macOS
# Installiert alle Abhängigkeiten und richtet den Autostart ein

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/share/speech2text"
BIN_DIR="$HOME/.local/bin"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.speech2text.plist"

echo "======================================"
echo "Speech2Text Setup für macOS"
echo "======================================"
echo ""

# Prüfe Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 nicht gefunden!"
    echo "   Bitte installiere Python 3: brew install python3"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✓ Python $PYTHON_VERSION gefunden"

# Erstelle Verzeichnisse
echo ""
echo "📁 Erstelle Verzeichnisse..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Kopiere Dateien
echo "📦 Kopiere Dateien..."
cp -r "$SCRIPT_DIR/speech2text" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"

# Erstelle Virtual Environment
echo ""
echo "🐍 Erstelle Virtual Environment..."
cd "$INSTALL_DIR"
python3 -m venv venv
source venv/bin/activate

# Installiere Abhängigkeiten
echo ""
echo "📥 Installiere Abhängigkeiten..."
pip install --upgrade pip > /dev/null
pip install -r requirements.txt

# Erstelle Executable Script
echo ""
echo "🔧 Erstelle Executable..."
cat > "$BIN_DIR/speech2text" << 'EOF'
#!/bin/bash
INSTALL_DIR="$HOME/.local/share/speech2text"
cd "$INSTALL_DIR"
source venv/bin/activate
exec python -m speech2text "$@"
EOF
chmod +x "$BIN_DIR/speech2text"

# Erstelle Stop-Script
cat > "$BIN_DIR/speech2text-stop" << 'EOF'
#!/bin/bash
if [ -f /tmp/speech2text.pid ]; then
    kill $(cat /tmp/speech2text.pid) 2>/dev/null && echo "Speech2Text beendet." || echo "Prozess nicht gefunden."
    rm -f /tmp/speech2text.pid /tmp/speech2text.lock
else
    echo "Speech2Text läuft nicht."
fi
EOF
chmod +x "$BIN_DIR/speech2text-stop"

# Füge ~/.local/bin zum PATH hinzu falls nötig
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo "📝 Füge $BIN_DIR zum PATH hinzu..."

    SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_RC="$HOME/.bash_profile"
    fi

    if [ -n "$SHELL_RC" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC"; then
            echo '' >> "$SHELL_RC"
            echo '# Speech2Text' >> "$SHELL_RC"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
            echo "   Hinzugefügt zu $SHELL_RC"
        fi
    fi
fi

# Frage nach LaunchAgent (Autostart)
echo ""
read -p "🚀 Autostart beim Login einrichten? (j/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "📝 Erstelle LaunchAgent..."
    cat > "$LAUNCH_AGENT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.speech2text</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_DIR/speech2text</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/speech2text.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/speech2text.log</string>
</dict>
</plist>
EOF
    echo "   ✓ LaunchAgent erstellt: $LAUNCH_AGENT"
    echo ""
    echo "   Autostart aktivieren:  launchctl load $LAUNCH_AGENT"
    echo "   Autostart deaktivieren: launchctl unload $LAUNCH_AGENT"
fi

# Lade Whisper-Modell vor
echo ""
read -p "📥 Whisper-Modell jetzt herunterladen? (empfohlen, ~500MB) (j/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "⏳ Lade Whisper-Modell herunter..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    python -c "from faster_whisper import WhisperModel; WhisperModel('small', device='cpu', compute_type='int8')"
    echo "   ✓ Modell heruntergeladen!"
fi

echo ""
echo "======================================"
echo "✅ Installation abgeschlossen!"
echo "======================================"
echo ""
echo "Nutzung:"
echo "  speech2text        - Startet das Tool"
echo "  speech2text-stop   - Stoppt das Tool"
echo ""
echo "Hotkey: Cmd+Shift+D (Start/Stop Aufnahme)"
echo ""
echo "⚠️  WICHTIG: Erteile Accessibility-Berechtigung:"
echo "   Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen"
echo "   → Terminal (oder iTerm2) erlauben"
echo ""

# Starte neues Terminal falls PATH noch nicht geladen
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "💡 Starte eine neue Terminal-Session oder führe aus:"
    echo "   source ~/.zshrc"
fi
