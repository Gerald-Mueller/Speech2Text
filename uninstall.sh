#!/bin/bash
# Speech2Text Uninstaller für macOS
# Vollständige Deinstallation

APP_DEST="/Applications/Speech2Text.app"
PLIST_NAME="com.speech2text.plist"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
MODEL_CACHE="$HOME/.cache/huggingface/hub/models--Systran--faster-whisper-small"

echo "======================================"
echo "Speech2Text Uninstaller"
echo "======================================"
echo ""

# Frage nach Bestätigung
read -p "Möchtest du Speech2Text wirklich deinstallieren? (j/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

echo ""

# 1. Stoppe laufende Prozesse
echo "⏹️  Stoppe Speech2Text..."
pkill -f "Speech2Text" 2>/dev/null || true
echo "   ✅ Prozesse gestoppt"

# 2. Entlade und lösche LaunchAgent
echo "🗑️  Entferne LaunchAgent..."
if [ -f "$LAUNCH_AGENTS/$PLIST_NAME" ]; then
    launchctl unload "$LAUNCH_AGENTS/$PLIST_NAME" 2>/dev/null || true
    rm -f "$LAUNCH_AGENTS/$PLIST_NAME"
    echo "   ✅ LaunchAgent entfernt"
else
    echo "   ℹ️  Kein LaunchAgent gefunden"
fi

# 3. Lösche App aus /Applications
echo "🗑️  Entferne Speech2Text.app..."
if [ -d "$APP_DEST" ]; then
    rm -rf "$APP_DEST"
    echo "   ✅ App entfernt"
else
    echo "   ℹ️  App nicht gefunden"
fi

# 4. Lösche temporäre Dateien
echo "🧹 Lösche temporäre Dateien..."
rm -f /tmp/speech2text.lock
rm -f /tmp/speech2text.pid
rm -f /tmp/speech2text.log
echo "   ✅ Temporäre Dateien gelöscht"

# 5. Frage ob Whisper-Modell gelöscht werden soll
echo ""
if [ -d "$MODEL_CACHE" ]; then
    read -p "Auch das Whisper-Modell löschen (~500MB)? (j/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Jj]$ ]]; then
        echo "🗑️  Lösche Whisper-Modell..."
        rm -rf "$MODEL_CACHE"
        echo "   ✅ Modell gelöscht"
    else
        echo "   ℹ️  Modell behalten"
    fi
fi

echo ""
echo "======================================"
echo "✅ Deinstallation abgeschlossen!"
echo "======================================"
echo ""
echo "Vergiss nicht, die Accessibility-Berechtigung zu entfernen:"
echo "   Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen"
echo "   → Speech2Text entfernen"
echo ""
