#!/usr/bin/env python3
"""Validate using the installed Omarchy contract and resolve qs.* for qmllint."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
shell = Path(os.environ.get('OMARCHY_PATH', '/usr/share/omarchy')) / 'shell'
linter = shutil.which('qmllint') or '/usr/lib/qt6/bin/qmllint'
subprocess.run(['omarchy', 'plugin', 'validate', str(root)], check=True)
with tempfile.TemporaryDirectory(prefix='tidal-qml-imports-') as imports:
    # Quickshell provides the qs prefix at runtime; qmllint needs it explicitly.
    Path(imports, 'qs').symlink_to(shell, target_is_directory=True)
    subprocess.run([linter, '-I', imports, *[str(root / name) for name in
        ['BarWidget.qml', 'Controller.qml', 'PlayerPanel.qml', 'Spectrum.qml']]], check=True)
print('Manifest and QML validation passed (dynamic shell facade warnings may remain).')
