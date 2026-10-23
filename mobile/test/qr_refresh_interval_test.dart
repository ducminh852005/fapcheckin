import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/viewmodels/live_session_viewmodel.dart';

void main() {
  test('QR refresh interval is one minute', () {
    expect(LiveSessionViewModel.qrCycleDuration, 60);
  });
}
