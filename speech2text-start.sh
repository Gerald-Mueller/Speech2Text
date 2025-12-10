#!/bin/bash
# Speech2Text starten

APP_DEST="/Applications/Speech2Text.app"
PLIST="$HOME/Library/LaunchAgents/com.speech2text.plist"

# Prüfe ob bereits läuft
if pgrep -f "Speech2Text" > /dev/null; then
    echo "Speech2Text läuft bereits."
    echo "Log: tail -f /tmp/speech2text.log"
    exit 0
fi

# Prüfe ob App installiert ist
if [ ! -d "$APP_DEST" ]; then
    echo "❌ Speech2Text.app nicht gefunden!"
    echo "   Bitte zuerst installieren mit: ./install.sh"
    exit 1
fi

# Starte via open -a
echo "Starte Speech2Text..."
open -a "$APP_DEST"

sleep 2

if pgrep -f "Speech2Text" > /dev/null; then
    echo "✅ Speech2Text gestartet!"
    echo "Hotkey: Ctrl+Shift+D"
    echo "Log: tail -f /tmp/speech2text.log"
else
    echo "❌ Fehler beim Starten"
    echo "Prüfe: cat /tmp/speech2text.log"
fi
