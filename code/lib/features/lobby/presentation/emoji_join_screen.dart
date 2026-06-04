import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:nsd/nsd.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import 'package:party_game_hub/core/utils/emoji_code.dart';
import 'lobby_provider.dart';

/// Màn hình nhập 4 Emoji để tham gia phòng — không cần IP, không cần gõ số.
/// Custom keyboard hiển thị đúng 16 emoji trong dictionary.
class EmojiJoinScreen extends StatefulWidget {
  const EmojiJoinScreen({super.key});

  @override
  State<EmojiJoinScreen> createState() => _EmojiJoinScreenState();
}

class _EmojiJoinScreenState extends State<EmojiJoinScreen> {
  final List<String> _tapped = [];
  bool _searching = false;
  bool _notFound = false;
  Timer? _searchTimeout;

  @override
  void initState() {
    super.initState();
    // Bắt đầu quét mDNS để tìm phòng.
    final lobby = context.read<LobbyProvider>();
    if (lobby.discoveredRooms.isEmpty && lobby.localPlayer != null) {
      lobby.discoverRooms(lobby.localPlayer!.name);
    }
  }

  @override
  void dispose() {
    _searchTimeout?.cancel();
    super.dispose();
  }

  void _tap(String emoji) {
    if (_tapped.length >= EmojiCode.codeLength || _searching) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tapped.add(emoji);
      _notFound = false;
    });
    if (_tapped.length == EmojiCode.codeLength) _tryConnect();
  }

  void _backspace() {
    if (_tapped.isEmpty || _searching) return;
    HapticFeedback.selectionClick();
    setState(() => _tapped.removeLast());
  }

  Future<void> _tryConnect() async {
    final code = _tapped.join();
    final lobby = context.read<LobbyProvider>();

    setState(() => _searching = true);

    // Tìm phòng trong danh sách đã discover có mã khớp.
    Service? match = _findRoom(lobby.discoveredRooms, code);

    if (match == null) {
      // Chờ tối đa 8 giây để phòng xuất hiện.
      _searchTimeout = Timer.periodic(const Duration(milliseconds: 500), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        final found = _findRoom(
          context.read<LobbyProvider>().discoveredRooms,
          code,
        );
        if (found != null) {
          t.cancel();
          _connect(found);
        }
      });
      Timer(const Duration(seconds: 8), () {
        _searchTimeout?.cancel();
        if (mounted && _searching) {
          setState(() {
            _searching = false;
            _notFound = true;
            _tapped.clear();
          });
        }
      });
    } else {
      _connect(match);
    }
  }

  Service? _findRoom(List<Service> rooms, String code) {
    for (final s in rooms) {
      final extracted = EmojiCode.extractCode(s.name ?? '');
      if (extracted == code) return s;
    }
    return null;
  }

  Future<void> _connect(Service service) async {
    _searchTimeout?.cancel();
    if (!mounted) return;
    try {
      await context.read<LobbyProvider>().joinRoom(service);
      if (mounted) context.go('/room');
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _notFound = true;
          _tapped.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Mật Khẩu Emoji'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              NeonTitle(
                'Nhập 4 Emoji\ncủa phòng',
                fontSize: 22,
                color: primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Host đọc to 4 emoji trên màn hình của họ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Slots hiển thị đã chọn
              _SlotRow(tapped: _tapped),
              const SizedBox(height: 12),
              if (_searching)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    CircularProgressIndicator(color: primary),
                    const SizedBox(height: 8),
                    Text(
                      'Đang tìm phòng...',
                      style: TextStyle(color: primary, fontSize: 13),
                    ),
                  ],
                )
              else if (_notFound)
                Text(
                  '❌ Không tìm thấy phòng. Kiểm tra lại emoji và cùng WiFi.',
                  style: const TextStyle(
                    color: Color(0xFFFF6584),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              // Custom emoji keyboard
              _EmojiKeyboard(
                onTap: _tap,
                onBackspace: _backspace,
                disabled: _searching,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final List<String> tapped;
  const _SlotRow({required this.tapped});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(EmojiCode.codeLength, (i) {
        final filled = i < tapped.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: filled
                ? primary.withValues(alpha: 0.15)
                : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? primary : Colors.white.withValues(alpha: 0.12),
              width: filled ? 2.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: filled
              ? Text(tapped[i], style: const TextStyle(fontSize: 30))
              : Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 22,
                  ),
                ),
        );
      }),
    );
  }
}

class _EmojiKeyboard extends StatelessWidget {
  final ValueChanged<String> onTap;
  final VoidCallback onBackspace;
  final bool disabled;
  const _EmojiKeyboard({
    required this.onTap,
    required this.onBackspace,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ...EmojiCode.dictionary.map(
              (e) =>
                  _EmojiKey(emoji: e, onTap: disabled ? null : () => onTap(e)),
            ),
            _EmojiKey(
              emoji: '⌫',
              isAction: true,
              onTap: disabled ? null : onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmojiKey extends StatelessWidget {
  final String emoji;
  final VoidCallback? onTap;
  final bool isAction;
  const _EmojiKey({
    required this.emoji,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: isAction ? const Color(0xFF4A1515) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAction
                ? const Color(0xFFFF6584).withValues(alpha: 0.4)
                : primary.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: isAction ? 20 : 28,
            color: isAction ? const Color(0xFFFF6584) : null,
          ),
        ),
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget themeWrapper(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    backgroundColor: AppTheme.bgDeep,
    body: Center(child: child),
  ),
);

@Preview(name: 'EmojiJoin - SlotRow (Empty)', wrapper: themeWrapper)
Widget previewSlotRowEmpty() => const _SlotRow(tapped: []);

@Preview(name: 'EmojiJoin - SlotRow (Partial)', wrapper: themeWrapper)
Widget previewSlotRowPartial() => const _SlotRow(tapped: ['🐶', '🐱']);

@Preview(name: 'EmojiJoin - SlotRow (Full)', wrapper: themeWrapper)
Widget previewSlotRowFull() => const _SlotRow(tapped: ['🐶', '🐱', '🐭', '🐹']);

@Preview(name: 'EmojiJoin - Keyboard', wrapper: themeWrapper)
Widget previewEmojiKeyboard() => Padding(
  padding: const EdgeInsets.all(16.0),
  child: _EmojiKeyboard(onTap: (_) {}, onBackspace: () {}, disabled: false),
);

@Preview(name: 'EmojiJoin - EmojiKey', wrapper: themeWrapper)
Widget previewEmojiKey() => Padding(
  padding: const EdgeInsets.all(16.0),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _EmojiKey(emoji: '🐶', onTap: () {}),
      const SizedBox(width: 16),
      _EmojiKey(emoji: '⌫', isAction: true, onTap: () {}),
    ],
  ),
);
