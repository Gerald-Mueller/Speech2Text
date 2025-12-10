"""Speech2Text - Hauptprogramm

Offline Speech-to-Text für macOS mit globalem Hotkey (Ctrl+Shift+D).
"""

import atexit
import fcntl
import os
import signal
import sys
import threading
import time
from pynput import keyboard

from .audio import AudioRecorder
from .transcribe import Transcriber
from .paste import paste_text

# Hotkey-Konfiguration
HOTKEY_COMBINATION = "<ctrl>+<shift>+d"
HOTKEY_DISPLAY = "Ctrl+Shift+D"

# Lock-Datei für Single-Instance
LOCK_FILE = "/tmp/speech2text.lock"
PID_FILE = "/tmp/speech2text.pid"

# Heartbeat-Intervall (Sekunden)
HEARTBEAT_INTERVAL = 30


def acquire_lock() -> int | None:
    """Versucht einen exklusiven Lock zu bekommen."""
    try:
        fd = os.open(LOCK_FILE, os.O_CREAT | os.O_RDWR)
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        os.ftruncate(fd, 0)
        os.write(fd, str(os.getpid()).encode())
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
        return fd
    except (OSError, IOError):
        return None


def release_lock(fd: int) -> None:
    """Gibt den Lock frei."""
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)
        os.unlink(LOCK_FILE)
        if os.path.exists(PID_FILE):
            os.unlink(PID_FILE)
    except OSError:
        pass


class Speech2Text:
    """Hauptklasse für das Diktiertool."""

    def __init__(self):
        self.recorder = AudioRecorder()
        self.transcriber = Transcriber()
        self.is_recording = False
        self.is_processing = False
        self.running = True
        self.listener = None

    def _heartbeat(self) -> None:
        """Heartbeat-Thread verhindert, dass der Prozess suspendiert wird."""
        while self.running:
            time.sleep(HEARTBEAT_INTERVAL)
            # Debug-Ausgabe nur wenn aktiv
            if self.is_recording:
                print("💓 Aufnahme läuft...", file=sys.stderr)

    def on_hotkey(self) -> None:
        """Wird aufgerufen wenn der Hotkey gedrückt wird."""
        if self.is_processing:
            print("⏳ Noch in Verarbeitung...", file=sys.stderr)
            return

        if self.is_recording:
            self.stop_recording()
        else:
            self.start_recording()

    def start_recording(self) -> None:
        """Startet die Audio-Aufnahme."""
        self.is_recording = True
        print(f"\n🎤 Aufnahme läuft... ({HOTKEY_DISPLAY} zum Stoppen)", file=sys.stderr)
        self.recorder.start()

    def stop_recording(self) -> None:
        """Stoppt die Aufnahme und transkribiert."""
        if not self.is_recording:
            return

        self.is_processing = True
        self.is_recording = False
        print("⏹️  Aufnahme gestoppt, transkribiere...", file=sys.stderr)

        try:
            audio_data = self.recorder.stop()

            if audio_data:
                text = self.transcriber.transcribe(audio_data)
                if text:
                    print(f"📝 Erkannt: {text}", file=sys.stderr)
                    paste_text(text)
                    print("✅ Text eingefügt!", file=sys.stderr)
                else:
                    print("⚠️  Kein Text erkannt", file=sys.stderr)
            else:
                print("⚠️  Keine Audio-Daten", file=sys.stderr)
        except Exception as e:
            print(f"❌ Fehler: {e}", file=sys.stderr)
        finally:
            self.is_processing = False

    def run(self) -> None:
        """Startet das Tool."""
        print("=" * 50, file=sys.stderr)
        print("Speech2Text gestartet!", file=sys.stderr)
        print("=" * 50, file=sys.stderr)
        print(f"Hotkey: {HOTKEY_DISPLAY} (Toggle Aufnahme)", file=sys.stderr)
        print("Beenden: Ctrl+C", file=sys.stderr)
        print("=" * 50, file=sys.stderr)

        # Lade Whisper-Modell im Voraus
        self.transcriber.load_model()

        print("\nBereit zum Diktieren!", file=sys.stderr)

        # Starte Heartbeat-Thread
        heartbeat_thread = threading.Thread(target=self._heartbeat, daemon=True)
        heartbeat_thread.start()

        # Versuche GlobalHotKeys (zuverlässiger)
        try:
            print(f"Verwende GlobalHotKeys für {HOTKEY_COMBINATION}", file=sys.stderr)
            with keyboard.GlobalHotKeys(
                {HOTKEY_COMBINATION: self.on_hotkey}
            ) as listener:
                self.listener = listener
                listener.join()
        except Exception as e:
            print(f"⚠️  GlobalHotKeys fehlgeschlagen: {e}", file=sys.stderr)
            print("Versuche Fallback mit Listener...", file=sys.stderr)
            self._run_with_listener()

    def _run_with_listener(self) -> None:
        """Fallback: Nutzt einfachen Listener statt GlobalHotKeys."""
        pressed_modifiers: set = set()
        hotkey_modifiers = {keyboard.Key.ctrl, keyboard.Key.shift}

        def on_press(key):
            if key in hotkey_modifiers:
                pressed_modifiers.add(key)
                return

            try:
                if hasattr(key, "char") and key.char and key.char.lower() == "d":
                    if pressed_modifiers == hotkey_modifiers:
                        self.on_hotkey()
            except AttributeError:
                pass

        def on_release(key):
            if key in hotkey_modifiers:
                pressed_modifiers.discard(key)

        with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
            self.listener = listener
            listener.join()

    def stop(self) -> None:
        """Stoppt das Tool sauber."""
        self.running = False
        if self.listener:
            self.listener.stop()


def main():
    """Entry-Point."""
    lock_fd = acquire_lock()
    if lock_fd is None:
        print("Speech2Text läuft bereits!", file=sys.stderr)
        print("Stoppen mit: speech2text-stop.sh", file=sys.stderr)
        print("Oder: kill $(cat /tmp/speech2text.pid)", file=sys.stderr)
        sys.exit(1)

    app = None

    def cleanup(signum=None, frame=None):
        if app:
            app.stop()
        release_lock(lock_fd)
        sys.exit(0)

    atexit.register(lambda: release_lock(lock_fd))
    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    try:
        app = Speech2Text()
        app.run()
    except KeyboardInterrupt:
        print("\n\nBeendet.", file=sys.stderr)
    except Exception as e:
        print(f"❌ Kritischer Fehler: {e}", file=sys.stderr)
        print("Prüfe Log: /tmp/speech2text.log", file=sys.stderr)
    finally:
        release_lock(lock_fd)


if __name__ == "__main__":
    main()
