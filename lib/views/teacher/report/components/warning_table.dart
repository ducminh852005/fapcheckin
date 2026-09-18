import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_colors.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/core/constants/app_text_styles.dart';

class WarningTable extends StatelessWidget {
  const WarningTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Cảnh báo vắng quá quy định', style: AppTextStyles.headlineSm),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusAbsentBg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '14 SV',
                          style: AppTextStyles.caption.copyWith(color: AppColors.statusAbsent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Sinh viên chạm ngưỡng >15% và vượt mốc >20%', style: AppTextStyles.caption),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Lọc nâng cao'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTextStyles.labelSm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _buildActionBtn('Gửi cảnh báo Email FPT', Icons.mail, AppColors.statusAbsent, AppColors.onError),
                _buildActionBtn('Đồng bộ Cổng Khảo Thí', Icons.sync, AppColors.surface, AppColors.textPrimary, iconColor: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3), // Sinh viên
                  1: FlexColumnWidth(1), // Lớp
                  2: FlexColumnWidth(1), // Vắng
                  3: FlexColumnWidth(1.5), // Trạng thái
                  4: FlexColumnWidth(1.2), // Thao tác
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                    ),
                    children: [
                      _buildTh('Sinh viên', align: TextAlign.left),
                      _buildTh('Lớp'),
                      _buildTh('Vắng', align: TextAlign.center),
                      _buildTh('Trạng thái'),
                      _buildTh('Thao tác', align: TextAlign.right),
                    ],
                  ),
                  
                  // Row 1
                  _buildTr('Trần Minh Quân', 'SE172340', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCcgism53pxDfTc2t-IN_UkQxYdXRQuYXMs2Gr4hviFbJhZMzkngOWk_e6HHI_fgIU-trFIs3JiLuGfmqnAcDNPN6VoXedu8eX486NtT2flHnsUKdZ8FK5QGS9zZNcnvCgNbPgOkRwWz15hrpjLlgfGxEtFdNhdzv0AQiZxHV-SFxGUZgJiT8czbbRD0O5r0OLu__98beFKYj5_3LbrepWbbIXnD06q4goWCxnvCg5e40uKcwdRdC1d1w', 'SWP391', '7/30', '23.3%', true, 'Cấm thi', true),
                  // Row 2
                  _buildTr('Nguyễn Thị Hải Yến', 'IA160892', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCBR1qBnGD8fezF9Ve7kLNuGvPzNKN6FjNMmNjDc-UWTCFb3ivlHj50TbvV2ETVzsR4G4W3RAy-JrXtMeSpiTcGgfq_JI1BoBbCnFfGadVXvHFPV0aiNJs85XVsPJgpLO0J7a0HaA8gIyWfiJYCIg8QrXMvfTplrE2CklOg-md3WamwkQcfd01ldwPGB7quil7OMemUqyZBlnK3_BvbffS2i2pfISs0--nQhuz991J7pgQ4D78IzMdLgA', 'PRJ301', '7/30', '23.3%', true, 'Cấm thi', true),
                  // Row 3
                  _buildTr('Lê Hoàng Nam', 'SE174510', 'https://lh3.googleusercontent.com/aida-public/AB6AXuB9dvqMIF0yf683oBqpTO-fiwllNm66g74yc91zqtLbAwGbuCN8N2QAc0-KZ7ihOypDvniXCxDpQOF3n-MCA5Cxa2O36ThbZvmLApx2FQpekepBPLsfGgx4gJTld8-RhJPkQFCc7mCbt1vJ1olD0XXbCHJiBspsLNf_8q5QSxXeOCdyTKnRpj65NPPGHO0NlrhaszPmgnz4UGnH67jLeaDDg7DPB0sBFh5K3nRWaRrZxWQfLkMGulfgWg', 'MAS291', '6/30', '20.0%', false, 'Nguy cơ cấm', false),
                  // Row 4
                  _buildTrNoImage('Phạm Tuấn Anh', 'SE170123', 'PT', AppColors.secondaryContainer, AppColors.onSecondaryContainer, 'SWP391', '5/30', '16.7%', false, 'Ngưỡng 15%', false),
                  // Row 5
                  _buildTrNoImage('Đỗ Đức Duy', 'AI170098', 'ĐD', const Color(0xFFcbe7f5), const Color(0xFF021f29), 'MAS291', '5/30', '16.7%', false, 'Ngưỡng 15%', false),
                ],
              ),
            ),
          ),
          
          // Footer
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hiển thị 5 / 14 sinh viên cần cảnh báo', style: AppTextStyles.caption),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTextStyles.labelSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Xem toàn bộ 14 sinh viên'),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color bgColor, Color textColor, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? textColor),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildTh(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _buildTr(
    String name, String rollNumber, String avatarUrl,
    String className, String absentStr, String percentStr, bool isAbsentRed,
    String status, bool isStatusRed
  ) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainer)),
      ),
      children: [
        _buildTdStudent(name, rollNumber, avatarUrl: avatarUrl),
        _buildTdClass(className),
        _buildTdAbsent(absentStr, percentStr, isAbsentRed),
        _buildTdStatus(status, isStatusRed),
        _buildTdActions(),
      ],
    );
  }

  TableRow _buildTrNoImage(
    String name, String rollNumber, String initials, Color initBg, Color initColor,
    String className, String absentStr, String percentStr, bool isAbsentRed,
    String status, bool isStatusRed
  ) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainer)),
      ),
      children: [
        _buildTdStudent(name, rollNumber, initials: initials, initBg: initBg, initColor: initColor),
        _buildTdClass(className),
        _buildTdAbsent(absentStr, percentStr, isAbsentRed),
        _buildTdStatus(status, isStatusRed),
        _buildTdActions(),
      ],
    );
  }

  Widget _buildTdStudent(String name, String rollNumber, {String? avatarUrl, String? initials, Color? initBg, Color? initColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      child: Row(
        children: [
          if (avatarUrl != null)
            ClipOval(
              child: Image.network(avatarUrl, width: 32, height: 32, fit: BoxFit.cover),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: initBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initials!, style: AppTextStyles.code.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: initColor)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelMd.copyWith(color: AppColors.textPrimary)),
                Text(rollNumber, style: AppTextStyles.code.copyWith(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTdClass(String className) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(className, style: AppTextStyles.code.copyWith(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildTdAbsent(String absentStr, String percentStr, bool isRed) {
    final color = isRed ? AppColors.statusAbsent : AppColors.statusLate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(absentStr, style: AppTextStyles.code.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(percentStr, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildTdStatus(String status, bool isRed) {
    final color = isRed ? AppColors.statusAbsent : AppColors.statusLate;
    final bg = isRed ? AppColors.statusAbsentBg : AppColors.statusLateBg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(status, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildTdActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _iconBtn(Icons.send),
          _iconBtn(Icons.visibility),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
