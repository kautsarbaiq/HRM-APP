import os

def fix_colors(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    original = content
    
    # Fix the syntax error: const Colors.white -> Colors.white
    content = content.replace('const Colors.white', 'Colors.white')
    
    if content != original:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Fixed {file_path}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_colors(os.path.join(root, file))

