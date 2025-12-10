#!/bin/bash
# Speech2Text Starter
# Das Python-Programm prüft selbst ob bereits eine Instanz läuft

cd "$(dirname "$0")"
source venv/bin/activate
exec python -m speech2text
