import os
import re

lib_dir = r"D:\Minh\IdeaProjects\fapcheckin\lib\views"

# Patterns and their replacements
patterns = [
    # Match width: 20 or width: 20.0, avoiding .w already there
    (re.compile(r'width:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'width: \1.w'),
    (re.compile(r'height:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'height: \1.h'),
    (re.compile(r'fontSize:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'fontSize: \1.sp'),
    (re.compile(r'circular\(\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)\s*\)'), r'circular(\1.r)'),
    (re.compile(r'EdgeInsets\.all\(\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)\s*\)'), r'EdgeInsets.all(\1.w)'),
    # For EdgeInsets symmetric and only
    (re.compile(r'horizontal:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'horizontal: \1.w'),
    (re.compile(r'vertical:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'vertical: \1.h'),
    (re.compile(r'left:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'left: \1.w'),
    (re.compile(r'right:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'right: \1.w'),
    (re.compile(r'top:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'top: \1.h'),
    (re.compile(r'bottom:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'bottom: \1.h'),
    # Icon sizes
    (re.compile(r'size:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'size: \1.w'),
    (re.compile(r'radius:\s*(\d+\.?\d*)(?!\.w|\.h|\.sp|\.r)'), r'radius: \1.r'),
]

import_statement = "import 'package:flutter_screenutil/flutter_screenutil.dart';"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Apply patterns
    for p, repl in patterns:
        content = p.sub(repl, content)
        
    if content != original_content:
        # We need to add import if it doesn't exist
        if import_statement not in content and 'flutter_screenutil' not in content:
            # Add after first import or material import
            if 'import \'package:flutter/material.dart\';' in content:
                content = content.replace('import \'package:flutter/material.dart\';', f'import \'package:flutter/material.dart\';\n{import_statement}')
            else:
                # Add at the top
                content = import_statement + '\n' + content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Modified: {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

# Also process core/theme/app_theme.dart and similar if they have hardcoded sizes
# Or widgets in core/widgets
