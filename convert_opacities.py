import os
import re

def convert_opacities(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    original = content
    
    content = content.replace('Colors.white.withOpacity(0.4)', 'Colors.white.withOpacity(0.1)')
    content = content.replace('Colors.white.withOpacity(0.5)', 'Colors.white.withOpacity(0.1)')
    content = content.replace('Colors.white.withOpacity(0.6)', 'Colors.white.withOpacity(0.15)')
    content = content.replace('Colors.white.withOpacity(0.7)', 'Colors.white.withOpacity(0.15)')
    content = content.replace('Colors.white.withOpacity(0.85)', 'Colors.white.withOpacity(0.2)')
    
    if content != original:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Updated {file_path}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            convert_opacities(os.path.join(root, file))

