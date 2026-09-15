import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/teacher_session_viewmodel.dart';

/// Biểu đồ % chuyên cần theo từng buổi học của một lớp — giúp GV thấy ngay
/// xu hướng đi học của lớp, cảnh báo khi SV gần ngưỡng cấm thi (ưu tiên
/// "NÊN CÓ" theo tài liệu kiến trúc).
///
/// Màn hình này giả định đã được bọc trong cùng một
/// `ChangeNotifierProvider<TeacherSessionViewModel>` với StartSessionScreen
/// (xem cách điều hướng ở StartSessionScreen) — nhờ vậy không cần lo lắng
/// việc phiên hiện tại có đang mở hay không mới xem được thống kê.
class ClassStatsScreen extends StatefulWidget {
  const ClassStatsScreen({super.key, required this.classId, required this.className});

  final String classId;
  final String className;

  @override
  State<ClassStatsScreen> createState() => _ClassStatsScreenState();
}

class _ClassStatsScreenState extends State<ClassStatsScreen> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback: đợi widget tree build xong khung hình đầu tiên
    // rồi mới gọi loadStats() (việc này sẽ gọi notifyListeners()). Nếu gọi
    // thẳng trong initState(), có nguy cơ notifyListeners() chạy ngay giữa
    // lúc Flutter đang build lần đầu — một lỗi runtime khá thường gặp khi
    // mới học Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherSessionViewModel>().loadStats(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chuyên cần · ${widget.className}')),
      body: Consumer<TeacherSessionViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.state == ViewState.error) {
            return Center(child: Text(viewModel.errorMessage ?? 'Lỗi tải thống kê'));
          }

          final stats = viewModel.stats;
          if (stats.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu buổi học nào.'));
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
            child: BarChart(
              BarChartData(
                maxY: 100,
                barGroups: [
                  for (var i = 0; i < stats.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: stats[i].presentPercent,
                          // Cảnh báo màu đỏ khi chuyên cần dưới 80% — ngưỡng
                          // ví dụ, chỉnh lại theo quy định thật của trường.
                          color: stats[i].presentPercent < 80 ? Colors.red : Colors.green,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= stats.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            stats[index].sessionLabel,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                  ),
                ),
                gridData: const FlGridData(drawVerticalLine: false),
              ),
            ),
          );
        },
      ),
    );
  }
}
