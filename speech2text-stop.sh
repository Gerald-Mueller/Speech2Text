#!/bin/bash
# Speech2Text stoppen

PLIST="$HOME/Library/LaunchAgents/com.speech2text.plist"

echo "Stoppe Speech2Text..."

# Entlade LaunchAgent
if [ -f "$PLIST" ]; then
    launchctl unload "$PLIST" 2>/dev/null || true
fi

# Beende alle Speech2Text Prozesse
pkill -f "Speech2Text" 2>/dev/null || true

# Räume auf
rm -f /tmp/speech2text.lock /tmp/speech2text.pid

echo "✅ Speech2Text gestoppt."
