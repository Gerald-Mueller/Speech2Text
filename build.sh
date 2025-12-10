#!/bin/bash
# Speech2Text Build Script
# Kompiliert die App mit PyInstaller

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "======================================"
echo "Speech2Text Build"
echo "======================================"
echo ""

# Prüfe ob venv existiert
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "📦 Erstelle Virtual Environment..."
    python3 -m venv venv
fi

source "$SCRIPT_DIR/venv/bin/activate"

# Prüfe ob PyInstaller installiert ist
if ! pip show pyinstaller > /dev/null 2>&1; then
    echo "📥 Installiere PyInstaller..."
    pip install pyinstaller -q
fi

# Prüfe ob Dependencies installiert sind
if ! pip show faster-whisper > /dev/null 2>&1; then
    echo "📥 Installiere Abhängigkeiten..."
    pip install -r requirements.txt -q
fi

echo "🔨 Kompiliere Speech2Text.app..."
echo "   Dies dauert etwa 1-2 Minuten..."
echo ""

pyinstaller Speech2Text.spec --clean --noconfirm 2>&1 | grep -E "(INFO|ERROR|WARNING):.*Building|completed|ERROR"

echo ""

if [ -d "$SCRIPT_DIR/dist/Speech2Text.app" ]; then
    SIZE=$(du -sh "$SCRIPT_DIR/dist/Speech2Text.app" | cut -f1)
    echo "======================================"
    echo "✅ Build erfolgreich!"
    echo "======================================"
    echo ""
    echo "App: $SCRIPT_DIR/dist/Speech2Text.app ($SIZE)"
    echo ""
    echo "Nächster Schritt:"
    echo "   ./install.sh"
    echo ""
else
    echo "❌ Build fehlgeschlagen!"
    echo "   Prüfe die Ausgabe oben für Details."
    exit 1
fi
