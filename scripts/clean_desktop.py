import os
import re

files_to_clean = [
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\settings\settings_body.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\settings\components\settings_header.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\report_body.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\components\warning_table.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\components\report_kpis.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\components\report_header.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\components\report_charts.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\components\checkin_modality.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\report\components\subject_comparison.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\live_session\live_session_body.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\live_session\components\qr_panel.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\class_management\dialogs\import_timetable_dialog.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\class_management\dialogs\create_class_dialog.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\attendance_history\components\session_detail_dialog.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\attendance_history\components\history_table.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\dashboard\components\sidebar.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\dashboard\components\stat_card.dart",
    r"D:\Minh\IdeaProjects\fapcheckin\lib\views\teacher\dashboard\components\top_bar.dart",
]

def clean_file(filepath):
    if not os.path.exists(filepath):
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

for f in files_to_clean:
    clean_file(f)
