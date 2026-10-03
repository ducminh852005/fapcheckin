import re

filepath = r"D:\Minh\IdeaProjects\fapcheckin\lib\views\auth\login_screen.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

original_content = content

# Remove .w, .h, .sp, .r from numbers
content = re.sub(r'(\d+\.?\d*)\.w', r'\1', content)
content = re.sub(r'(\d+\.?\d*)\.h', r'\1', content)
content = re.sub(r'(\d+\.?\d*)\.sp', r'\1', content)
content = re.sub(r'(\d+\.?\d*)\.r', r'\1', content)

if content != original_content:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Cleaned login_screen.dart")
