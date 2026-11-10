import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fapcheckin_core/constants/app_palette.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

import '../../../core/widgets/app_toast.dart';
import '../../../viewmodels/ai_chat_viewmodel.dart';
import 'components/ai_confirm_card.dart';
import 'components/ai_message_bubble.dart';

/// Tab "AI": trợ lý trò chuyện (gõ hoặc nói) giúp giảng viên điểm danh, tra cứu và xem báo cáo.
/// Thao tác ghi luôn qua thẻ xác nhận; tool đọc chạy ngay.
class AiBody extends StatefulWidget {
  const AiBody({super.key});

  @override
  State<AiBody> createState() => _AiBodyState();
}

class _AiBodyState extends State<AiBody> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  int _lastCount = 0;
  String? _shownVoiceError;
  AiChatViewModel? _vm;

  static const _suggestions = [
    (Icons.insights_rounded, 'Báo cáo chuyên cần tổng quan', 'Báo cáo chuyên cần tổng quan của các lớp tôi'),
    (Icons.warning_amber_rounded, 'Sinh viên có nguy cơ vắng nhiều', 'Sinh viên nào đang có nguy cơ vắng nhiều?'),
    (Icons.event_note_rounded, 'Hôm nay tôi dạy lớp nào?', 'Hôm nay tôi dạy những lớp nào, slot nào?'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= context.read<AiChatViewModel>();
  }

  @override
  void dispose() {
    // Rời tab AI thì tắt Live/đọc/nghe để micro không chạy ngầm.
    final vm = _vm;
    if (vm != null && (vm.live || vm.listening || vm.speaking)) unawaited(vm.stopLive());
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(AiChatViewModel vm, [String? text]) async {
    final value = (text ?? _controller.text).trim();
    if (value.isEmpty) return; // luôn gửi được: lúc AI đang xử lý thì gộp, lúc đang ghi/chờ xác nhận thì xếp hàng
    _controller.clear();
    _focus.unfocus();
    await vm.send(value);
  }

  void _setTranscript(String text) {
    if (!mounted) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _toggleMic(AiChatViewModel vm) async {
    final ok = await vm.toggleListening(_setTranscript);
    if (!mounted) return;
    if (!ok && vm.voiceError != null) {
      showAppToast(context, message: vm.voiceError!, type: AppToastType.warning, title: 'Micro');
    }
  }

  Future<void> _toggleLive(AiChatViewModel vm) async {
    final ok = await vm.toggleLive(_setTranscript);
    if (!mounted) return;
    if (!ok && vm.voiceError != null) {
      showAppToast(context, message: vm.voiceError!, type: AppToastType.warning, title: 'Micro');
    }
  }

  Future<void> _confirm(AiChatViewModel vm) async {
    final ok = await vm.confirmPending();
    if (!mounted) return;
    showAppToast(
      context,
      message: ok ? 'Đã ghi điểm danh.' : 'Không ghi được điểm danh.',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiChatViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.isMobile ? 16.0 : context.pagePadding;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Chừa chỗ cho thanh điều hướng nổi ở dưới khi là điện thoại.
    final bottomPad = context.isMobile ? (keyboardOpen ? 8.0 : 92.0) : 16.0;

    // Lỗi micro/giọng đọc phát sinh giữa chừng (không do người dùng bấm) cũng phải hiện ra.
    final voiceError = vm.voiceError;
    if (voiceError != null && voiceError != _shownVoiceError) {
      _shownVoiceError = voiceError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showAppToast(context, message: voiceError, type: AppToastType.warning, title: 'Giọng nói');
        }
      });
    } else if (voiceError == null) {
      _shownVoiceError = null;
    }

    if (vm.messages.length != _lastCount) {
      _lastCount = vm.messages.length;
      _scrollToEnd();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (!isDark)
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppPalette.headerGradient),
            ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 6),
                      child: _Header(
                        hasMessages: vm.messages.isNotEmpty,
                        backupAi: vm.usingBackupAi,
                        voiceSupported: vm.voiceSupported,
                        voiceReplies: vm.voiceReplies,
                        onToggleReplies: () => vm.setVoiceReplies(!vm.voiceReplies),
                        onReset: vm.busy ? null : vm.reset,
                      ),
                    ),
                    Expanded(
                      child: vm.messages.isEmpty
                          ? _Welcome(
                              hPad: hPad,
                              suggestions: _suggestions,
                              onPick: (prompt) => _send(vm, prompt),
                              onTemplate: () {
                                _controller.text = 'Điểm danh sinh viên ';
                                _controller.selection = TextSelection.collapsed(
                                  offset: _controller.text.length,
                                );
                                _focus.requestFocus();
                              },
                            )
                          : ListView.builder(
                              key: const Key('ai-messages'),
                              controller: _scroll,
                              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
                              itemCount: vm.messages.length + (vm.sending ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i == vm.messages.length) return const _Typing();
                                final m = vm.messages[i];
                                if (m.action != null) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: AiConfirmCard(
                                      action: m.action!,
                                      state: m.actionState,
                                      busy: vm.sending,
                                      onConfirm: () => _confirm(vm),
                                      onCancel: vm.cancelPending,
                                    ),
                                  );
                                }
                                return AiMessageBubble(
                                  text: m.text,
                                  isUser: m.role == AiMessageRole.user,
                                  isError: m.isError,
                                  onRetry: m.isError && i == vm.messages.length - 1 && vm.canRetry
                                      ? vm.retry
                                      : null,
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 6, hPad, bottomPad),
                      child: _InputBar(
                        controller: _controller,
                        focus: _focus,
                        listening: vm.listening,
                        live: vm.live,
                        statusText: vm.statusText,
                        onLive: () => _toggleLive(vm),
                        canInterrupt: vm.canInterrupt,
                        onStop: vm.interrupt,
                        busy: vm.busy,
                        awaitingConfirm: vm.pendingAction != null,
                        voiceSupported: vm.voiceSupported,
                        onMic: () => _toggleMic(vm),
                        onSend: () => _send(vm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.hasMessages,
    required this.backupAi,
    required this.voiceSupported,
    required this.voiceReplies,
    required this.onToggleReplies,
    required this.onReset,
  });

  final bool hasMessages;
  final bool backupAi;
  final bool voiceSupported;
  final bool voiceReplies;
  final VoidCallback onToggleReplies;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.primary, Color(0xFFFF8A4C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trợ lý AI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? const Color(0xFFF8FAFC) : AppPalette.textDark,
                ),
              ),
              Text(
                backupAi
                    ? 'Đang dùng AI dự phòng (chạy local)'
                    : 'Nói hoặc gõ để điểm danh, tra cứu, xem báo cáo',
                key: const Key('ai-subtitle'),
                style: TextStyle(
                  fontSize: 12,
                  color: backupAi
                      ? const Color(0xFFD97706)
                      : (isDark ? const Color(0xFF94A3B8) : AppPalette.textMuted),
                ),
              ),
            ],
          ),
        ),
        if (voiceSupported)
          Tooltip(
            message: voiceReplies ? 'Tắt đọc to câu trả lời' : 'Bật đọc to câu trả lời',
            child: IconButton(
              key: const Key('ai-voice-mode'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onToggleReplies,
              icon: Icon(voiceReplies ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            ),
          ),
        if (hasMessages)
          Tooltip(
            message: 'Cuộc trò chuyện mới',
            child: IconButton(
              key: const Key('ai-reset'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onReset,
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.hPad,
    required this.suggestions,
    required this.onPick,
    required this.onTemplate,
  });

  final double hPad;
  final List<(IconData, String, String)> suggestions;
  final void Function(String prompt) onPick;
  final VoidCallback onTemplate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : AppPalette.textMuted;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mình có thể giúp gì hôm nay?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ví dụ: "Điểm danh sinh viên HE123456 lớp SWP391 slot 3 có mặt". '
            'Mọi thao tác ghi đều cần bạn xác nhận trước.\n\n'
            'Mic: nói MỘT câu, AI trả lời rồi dừng (bấm mic lần nữa khi nói xong để gửi ngay).\n'
            'Live: hội thoại liên tục, AI đọc to phần tóm tắt rồi tự nghe tiếp cho tới khi bạn bấm dừng.',
            style: TextStyle(fontSize: 13, height: 1.45, color: muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label, prompt) in suggestions)
                _Chip(icon: icon, label: label, onTap: () => onPick(prompt)),
              _Chip(
                icon: Icons.how_to_reg_rounded,
                label: 'Điểm danh sinh viên…',
                onTap: onTemplate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.outline : AppPalette.orangeBorder,
        ),
      ),
      child: InkWell(
        key: Key('ai-chip-$label'),
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppPalette.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : AppPalette.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        key: Key('ai-typing'),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.primary),
            ),
            SizedBox(width: 10),
            Text('Đang xử lý…', style: TextStyle(fontSize: 13, color: AppPalette.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focus,
    required this.listening,
    required this.live,
    required this.statusText,
    required this.onLive,
    required this.canInterrupt,
    required this.onStop,
    required this.busy,
    required this.awaitingConfirm,
    required this.voiceSupported,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool listening;
  final bool live;
  final String? statusText;
  final VoidCallback onLive;
  final bool canInterrupt;
  final VoidCallback onStop;
  final bool busy;
  final bool awaitingConfirm;
  final bool voiceSupported;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final hint = listening
        ? 'Đang nghe… hãy nói'
        : awaitingConfirm
        ? 'Xác nhận/huỷ thẻ phía trên, hoặc gõ thêm yêu cầu…'
        : 'Nhập hoặc nói yêu cầu của bạn…';

    final bar = Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: listening
              ? AppPalette.statusRed
              : (isDark ? scheme.outline : AppPalette.borderSubtle),
          width: listening ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('ai-input'),
              controller: controller,
              focusNode: focus,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (voiceSupported)
            Semantics(
              button: true,
              label: live ? 'Tắt trợ lý Live' : 'Bật trợ lý Live (hội thoại liên tục)',
              child: IconButton(
                key: const Key('ai-live'),
                tooltip: live ? 'Tắt Live' : 'Trợ lý Live',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onLive,
                style: live
                    ? IconButton.styleFrom(backgroundColor: AppPalette.primary.withValues(alpha: 0.14))
                    : null,
                icon: Icon(
                  live ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                  color: AppPalette.primary,
                  size: 24,
                ),
              ),
            ),
          if (voiceSupported && !live)
            Semantics(
              button: true,
              label: listening ? 'Nói xong, gửi ngay' : 'Nói một câu',
              child: IconButton(
                key: const Key('ai-mic'),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onMic, // luôn dùng được: nói thêm lúc AI đang xử lý sẽ được gộp vào ngữ cảnh
                icon: Icon(
                  listening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: listening ? AppPalette.statusRed : AppPalette.primary,
                  size: 26,
                ),
              ),
            ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final empty = value.text.trim().isEmpty;
              // AI đang đọc/xử lý và chưa gõ gì: nút Dừng. Đã gõ chữ: nút Gửi (gửi sẽ ngắt AI rồi trả lời câu mới).
              if (canInterrupt && empty) {
                return Semantics(
                  button: true,
                  label: 'Dừng AI',
                  child: IconButton.filled(
                    key: const Key('ai-stop'),
                    tooltip: 'Dừng',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: onStop,
                    style: IconButton.styleFrom(
                      backgroundColor: AppPalette.statusRed,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_rounded),
                  ),
                );
              }
              return Semantics(
                button: true,
                label: 'Gửi',
                child: IconButton.filled(
                  key: const Key('ai-send'),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              );
            },
          ),
        ],
      ),
    );

    if (statusText == null && !live) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: canInterrupt ? onStop : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
          child: Row(
            key: const Key('ai-status'),
            children: [
              Icon(live ? Icons.graphic_eq_rounded : Icons.info_outline_rounded, size: 16, color: AppPalette.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  (live ? 'Live · ${statusText ?? 'Sẵn sàng'}' : statusText!) + (canInterrupt ? ' · chạm để dừng' : ''),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppPalette.primary),
                ),
              ),
            ],
          ),
          ),
        ),
        bar,
      ],
    );
  }
}
