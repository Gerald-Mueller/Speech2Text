#!/bin/bash
# Speech2Text Installer für macOS
# Installiert die kompilierte App und konfiguriert Autostart

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Speech2Text.app"
APP_SOURCE="$SCRIPT_DIR/dist/$APP_NAME"
APP_DEST="/Applications/$APP_NAME"
PLIST_NAME="com.speech2text.plist"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
MODEL_CACHE="$HOME/.cache/huggingface/hub/models--Systran--faster-whisper-small"

echo "======================================"
echo "Speech2Text Installer"
echo "======================================"
echo ""

# Prüfe ob kompilierte App existiert
if [ ! -d "$APP_SOURCE" ]; then
    echo "❌ Kompilierte App nicht gefunden!"
    echo "   Bitte zuerst bauen mit: ./build.sh"
    exit 1
fi

# Stoppe laufende Instanz
if pgrep -f "Speech2Text" > /dev/null 2>&1; then
    echo "⏹️  Stoppe laufende Instanz..."
    pkill -f "Speech2Text" 2>/dev/null || true
    sleep 1
fi

# Entlade alten LaunchAgent
if [ -f "$LAUNCH_AGENTS/$PLIST_NAME" ]; then
    echo "⏹️  Entlade alten LaunchAgent..."
    launchctl unload "$LAUNCH_AGENTS/$PLIST_NAME" 2>/dev/null || true
fi

# Lösche alte App falls vorhanden
if [ -d "$APP_DEST" ]; then
    echo "🗑️  Entferne alte Version..."
    rm -rf "$APP_DEST"
fi

# Kopiere App nach /Applications
echo "📦 Installiere Speech2Text.app..."
cp -R "$APP_SOURCE" "$APP_DEST"

echo "✅ App installiert nach $APP_DEST"

# LaunchAgent erstellen
echo ""
echo "📝 Erstelle LaunchAgent für Autostart..."
mkdir -p "$LAUNCH_AGENTS"

cat > "$LAUNCH_AGENTS/$PLIST_NAME" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.speech2text</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>$APP_DEST</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/speech2text.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/speech2text.log</string>
</dict>
</plist>
EOF

echo "✅ LaunchAgent erstellt"

# Whisper-Modell prüfen/herunterladen
echo ""
if [ -d "$MODEL_CACHE" ]; then
    echo "✅ Whisper-Modell bereits vorhanden"
else
    echo "📥 Lade Whisper-Modell herunter (~500MB)..."
    echo "   Dies kann einige Minuten dauern..."
    # Starte App kurz um Modell zu laden, dann stoppe wieder
    open -a "$APP_DEST"
    echo "   Warte auf Modell-Download..."
    sleep 30
    pkill -f "Speech2Text" 2>/dev/null || true
    echo "✅ Modell geladen"
fi

# LaunchAgent laden und App starten
echo ""
echo "🚀 Starte Speech2Text..."
launchctl load "$LAUNCH_AGENTS/$PLIST_NAME"

sleep 3

# Prüfe ob gestartet
if pgrep -f "Speech2Text" > /dev/null; then
    echo "✅ Speech2Text läuft!"
else
    echo "⚠️  Speech2Text konnte nicht gestartet werden"
    echo "   Prüfe Log: tail -f /tmp/speech2text.log"
fi

echo ""
echo "======================================"
echo "✅ Installation abgeschlossen!"
echo "======================================"
echo ""
echo "Hotkey: Ctrl+Shift+D (Start/Stop Aufnahme)"
echo ""
echo "⚠️  WICHTIG: Accessibility-Berechtigung erforderlich!"
echo ""
echo "   1. Öffne: Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen"
echo "   2. Klicke auf '+'"
echo "   3. Wähle 'Speech2Text' aus /Applications"
echo "   4. Aktiviere die Checkbox"
echo ""
echo "   Nach dem Hinzufügen, starte neu mit:"
echo "   ./speech2text-stop.sh && ./speech2text-start.sh"
echo ""
echo "Befehle:"
echo "   ./speech2text-start.sh  - Manuell starten"
echo "   ./speech2text-stop.sh   - Stoppen"
echo "   ./uninstall.sh          - Deinstallieren"
echo ""
echo "Log anzeigen:"
echo "   tail -f /tmp/speech2text.log"
echo ""
