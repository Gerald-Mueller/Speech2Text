# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec file for Speech2Text

import os
import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# Sammle alle benötigten Daten
datas = []
datas += collect_data_files('faster_whisper')

# Hidden imports für alle Dependencies
hiddenimports = [
    'pynput.keyboard._darwin',
    'pynput.mouse._darwin',
    'sounddevice',
    'numpy',
    'ctranslate2',
    'huggingface_hub',
    'tokenizers',
    'pyperclip',
]
hiddenimports += collect_submodules('faster_whisper')
hiddenimports += collect_submodules('ctranslate2')

a = Analysis(
    ['run_speech2text.py'],
    pathex=[],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Speech2Text',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch='arm64',
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Speech2Text',
)

app = BUNDLE(
    coll,
    name='Speech2Text.app',
    icon=None,
    bundle_identifier='com.local.speech2text',
    info_plist={
        'CFBundleName': 'Speech2Text',
        'CFBundleDisplayName': 'Speech2Text',
        'CFBundleVersion': '1.0.0',
        'CFBundleShortVersionString': '1.0.0',
        'LSBackgroundOnly': True,
        'NSHighResolutionCapable': True,
        'LSArchitecturePriority': ['arm64'],
        'NSMicrophoneUsageDescription': 'Speech2Text benötigt Mikrofonzugriff für Spracherkennung.',
    },
)
