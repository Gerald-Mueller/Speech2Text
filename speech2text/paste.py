"""Text-Einfüge Modul

Nutzt pynput für Tastatureingaben - läuft im selben Prozess wie Speech2Text.app
und nutzt dessen Accessibility-Berechtigung.
"""

import time
import pyperclip
from pynput.keyboard import Controller, Key


# Keyboard Controller für Tastatureingaben
keyboard = Controller()


def paste_text(text: str) -> None:
    """Fügt Text ins aktive Fenster ein.

    Der Text wird in die Zwischenablage kopiert und dann via Cmd+V eingefügt.
    Nutzt pynput statt osascript - teilt die Accessibility-Berechtigung mit Speech2Text.app.
    """
    if not text:
        return

    # Kopiere Text in Zwischenablage
    pyperclip.copy(text)

    # Kurze Pause damit Clipboard bereit ist
    time.sleep(0.1)

    # Cmd+V via pynput (nutzt Speech2Text.app Berechtigung)
    keyboard.press(Key.cmd)
    keyboard.press('v')
    keyboard.release('v')
    keyboard.release(Key.cmd)
