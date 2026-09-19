import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  int _selectedTypeIndex = 0;
  int _selectedSlot = 2; // Default to Slot 2 as in image
  
  bool _autoQR = true;
  bool _sendEmail = true;
  bool _syncFap = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLearningType(),
                    const SizedBox(height: 20),
                    _buildClassAndDateRow(),
                    const SizedBox(height: 20),
                    _buildSlotSelection(),
                    const SizedBox(height: 20),
                    _buildRoomAndMethodRow(),
                    const SizedBox(height: 20),
                    _buildNoteInput(),
                    const SizedBox(height: 20),
                    _buildSettingsBox(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_available, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tạo lịch học mới & Đăng ký dạy bù',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FAP Sync',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Lên lịch buổi học bổ sung, học bù hoặc phụ đạo đồ án cho sinh viên FPT University',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Loại hình học tập'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildTypeOption(0, 'Học bù kế hoạch', Icons.schedule),
              _buildTypeOption(1, 'Phụ đạo / Workshop', Icons.co_present_outlined),
              _buildTypeOption(2, 'Review đồ án', Icons.workspace_premium_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(int index, String title, IconData icon) {
    final isSelected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTypeIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassAndDateRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  _buildSectionTitle('Lớp học & Học phần'),
                ],
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: 'SWP391 - SE1704 (Dự án Phần mềm)',
                items: ['SWP391 - SE1704 (Dự án Phần mềm)'],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  _buildSectionTitle('Ngày học dự kiến'),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  '28/10/2023 (Thứ Bảy)',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Chọn Ca học (Slot FPT Edu)'),
            const Text(
              '2h 20p / Ca',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _buildSlotCard(1, '07:30 - 09:50'),
            _buildSlotCard(2, '10:00 - 12:20'),
            _buildSlotCard(3, '12:50 - 15:10'),
            _buildSlotCard(4, '15:20 - 17:40'),
            _buildSlotCard(5, '17:50 - 20:10'),
            _buildSlotCard(6, '20:15 - 22:35'),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotCard(int slot, String time) {
    final isSelected = _selectedSlot == slot;
    return GestureDetector(
      onTap: () => setState(() => _selectedSlot = slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Slot $slot',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAndMethodRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.domain, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  _buildSectionTitle('Phòng học & Giảng đường'),
                ],
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: 'P.302 (Tòa Alpha) • Trống phòng',
                items: ['P.302 (Tòa Alpha) • Trống phòng'],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.devices, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  _buildSectionTitle('Hình thức giảng dạy'),
                ],
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: 'Trực tiếp tại phòng học (On-Campus)',
                items: ['Trực tiếp tại phòng học (On-Campus)'],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nội dung buổi học / Lý do đăng ký'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            initialValue: 'Dạy bù kiến thức Sprint 3 kiến trúc Microservices & Hướng dẫn triển khai CI/CD do lớp nghỉ lễ 20/10.',
            maxLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Thiết lập cơ chế điểm danh & Tự động hóa',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCheckboxRow('Tự động kích hoạt phòng điểm danh Dynamic QR 20s cho ca này', Icons.qr_code, _autoQR, (v) => setState(() => _autoQR = v!)),
          const SizedBox(height: 8),
          _buildCheckboxRow('Gửi thông báo & email lịch học bù đến 35 sinh viên lớp SE1704', Icons.mail_outline, _sendEmail, (v) => setState(() => _sendEmail = v!)),
          const SizedBox(height: 8),
          _buildCheckboxRow('Đồng bộ trực tiếp lên cổng đào tạo học vụ FAP Edu', Icons.sync_alt, _syncFap, (v) => setState(() => _syncFap = v!)),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String title, IconData icon, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ),
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: Colors.grey.shade400, width: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Xác thực bởi tài khoản GV. Nguyễn Văn An',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement save
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Xác nhận tạo lịch học'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {},
        ),
      ),
    );
  }
}
