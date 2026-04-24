import os
import re

def convert_to_dark(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    original = content
    
    # Text Colors
    content = content.replace('Color(0xFF0F172A)', 'Colors.white')
    content = content.replace('Color(0xFF475569)', 'Colors.white')
    content = content.replace('Color(0xFF64748B)', 'Color(0xFF94A3B8)')
    
    # Backgrounds & Cards
    content = content.replace('Color(0xFFF8FAFC)', 'Color(0xFF1E293B)')
    content = content.replace('Color(0xFFF1F5F9)', 'Color(0xFF0F172A)')
    
    # Borders & Dividers
    content = content.replace('Color(0xFFE2E8F0)', 'Color(0xFF334155)')
    content = content.replace('Color(0xFFCBD5E1)', 'Color(0xFF475569)')
    
    # White background in light mode -> translucent dark
    # Note: be careful not to replace text that needs to be white.
    # Usually white backgrounds are used like Colors.white or color: Colors.white.
    # We will manually replace specific files for glass cards.

    if content != original:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Updated {file_path}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            convert_to_dark(os.path.join(root, file))

