import os
import re

lib_dir = r"D:\Minh\IdeaProjects\fapcheckin\lib\views"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Remove const before Widgets and collections
    # e.g., const SizedBox -> SizedBox
    # const [ -> [
    # const { -> {
    # const EdgeInsets -> EdgeInsets
    
    # regex: const\s+ followed by capital letter or [ or {
    content = re.sub(r'const\s+([A-Z\[\{])', r'\1', content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Modified: {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
