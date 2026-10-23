#!/usr/bin/env python3
"""The native product may link Firebase Auth/Core only; historical export scripts are separate."""
import json
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
config = json.loads((root/'firebase/firebase.json').read_text())
assert not any(k in config for k in ('functions','firestore','storage'))
assert set(config['emulators']) <= {'auth','ui','singleProjectMode','hub','logging'}
products = set(re.findall(r'productName = (Firebase\w+);', (root/'wutzup.xcodeproj/project.pbxproj').read_text()))
assert products <= {'FirebaseAuth', 'FirebaseCore'}, f'Non-Auth SDK products: {sorted(products - {"FirebaseAuth", "FirebaseCore"})}'
for file in (root/'Wutzup').rglob('*.swift'):
    imports = set(re.findall(r'import (Firebase\w+)', file.read_text()))
    assert imports <= {'FirebaseAuth', 'FirebaseCore'}, str(file)
    assert not re.search(r'cloudfunctions\.net|a\.run\.app', file.read_text()), str(file)
print('Firebase Auth-only product boundary passed')
