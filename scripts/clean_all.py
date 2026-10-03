import os
import re

lib_dir = r"D:\Minh\IdeaProjects\fapcheckin\lib"

def clean_file(filepath):
    if not filepath.endswith('.dart'):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Remove .w, .h, .sp, .r
    content = re.sub(r'(\d+\.?\d*)\.w', r'\1', content)
    content = re.sub(r'(\d+\.?\d*)\.h', r'\1', content)
    content = re.sub(r'(\d+\.?\d*)\.sp', r'\1', content)
    content = re.sub(r'(\d+\.?\d*)\.r', r'\1', content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Cleaned {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        clean_file(os.path.join(root, file))
